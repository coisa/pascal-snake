"""Smoke do binário Pascal em PTYs sintéticos; somente biblioteca padrão."""

import argparse
import fcntl
import os
import pty
import select
import struct
import subprocess
import termios
import time
import uuid


class Terminal:
    def __init__(self, command, rows=24, columns=80):
        self.master, self.slave = pty.openpty()
        self.resize(rows, columns)
        self.original_mode = termios.tcgetattr(self.slave)
        self.data = b""
        self.process = subprocess.Popen(
            command, stdin=self.slave, stdout=self.slave, stderr=self.slave,
            env={**os.environ, "TERM": "xterm-256color"},
            start_new_session=True,
        )

    def resize(self, rows, columns):
        fcntl.ioctl(self.slave, termios.TIOCSWINSZ,
                    struct.pack("HHHH", rows, columns, 0, 0))

    def collect(self, seconds=0.1):
        deadline = time.monotonic() + seconds
        while time.monotonic() < deadline:
            ready, _, _ = select.select([self.master], [], [], 0.02)
            if ready:
                self.data += os.read(self.master, 65536)
                assert len(self.data) < 2_000_000, "unexpected output flood"

    def expect(self, text, since=0, timeout=5):
        deadline = time.monotonic() + timeout
        while text not in self.data[since:] and time.monotonic() < deadline:
            self.collect(0.03)
        assert text in self.data[since:], (
            f"missing {text!r}; exit={self.process.poll()}; "
            f"tail={self.data[-300:]!r}"
        )

    def send(self, keys):
        start = len(self.data)
        os.write(self.master, keys)
        return start

    def finish(self, key=b"q"):
        start = self.send(key)
        self.expect(b"JOGO ENCERRADO.", start)
        assert self.process.wait(timeout=5) == 0, "game exit status"
        self.collect()
        assert b"\x1b[?25h" in self.data[start:], f"cursor not restored: {self.data[start:]!r}"
        assert termios.tcgetattr(self.slave) == self.original_mode, "TTY mode not restored"

    def close(self):
        if self.process.poll() is None:
            self.process.terminate()
            try:
                self.process.wait(timeout=3)
            except subprocess.TimeoutExpired:
                self.process.kill()
                self.process.wait(timeout=3)
        os.close(self.master)
        os.close(self.slave)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("executable", nargs="?", default="./build/SnakeGame")
    parser.add_argument("--docker", metavar="IMAGE")
    args = parser.parse_args()
    name = "pascal-snake-smoke-" + uuid.uuid4().hex
    container_flags = ["--rm", "--network", "none", "--read-only",
                       "--cap-drop", "ALL", "--security-opt", "no-new-privileges"]

    def command(arguments, interactive=False):
        if args.docker:
            tty = ["-it", "--name", name] if interactive else []
            return ["docker", "run", *container_flags, *tty, args.docker, *arguments]
        return [args.executable, *arguments]

    def cli(arguments):
        return subprocess.run(command(arguments), capture_output=True, timeout=15)

    result = cli(["--help"])
    assert result.returncode == 0 and b"Pascal Snake" in result.stdout
    assert b"\x1b" not in result.stdout, "help must be pipe-friendly"
    for arguments in (["--unknown"], ["--seed"], ["--seed", "-1"],
                      ["--seed", "4294967296"], ["--seed", "abc"],
                      ["--seed", ""], ["--seed", "0x10"], ["--seed", "+1"],
                      ["--seed", " 1"], ["--seed", "1", "extra"]):
        result = cli(arguments)
        assert result.returncode == 2, f"accepted invalid arguments: {arguments}"
        assert b"terminal interativo" not in result.stderr, "invalid input reached game"
    for seed in ("0", "42", "4294967295"):
        result = cli(["--seed", seed])
        assert result.returncode == 2 and b"terminal interativo" in result.stderr
    print("ok - help, decimal seeds, invalid arguments and non-TTY rejection")

    terminals = []
    try:
        game = Terminal(command(["--seed", "42"], True))
        terminals.append(game)
        game.expect(b"PRONTO PARA JOGAR?")
        game.expect(b"PONTOS")
        game.expect(b"RECORDE")
        # Selecionar a velocidade, iniciar, pausar e provar que nada avança.
        mark = game.send(b"1")
        game.expect(b"CALMO", mark)
        game.send(b"\r")
        game.collect(0.25)
        mark = game.send(b"p")
        game.expect(b"PAUSADO", mark)
        game.collect(0.1)
        paused_output = len(game.data)
        game.collect(0.45)
        assert len(game.data) == paused_output, "paused game still redraws or advances"
        # Setas reais passam pelo parser de teclado do Crt.
        game.send(b" ")
        game.collect(0.08)
        game.send(b"\x1b[A")
        game.collect(0.25)
        assert game.process.poll() is None, "arrow incorrectly interpreted as quit"
        mark = game.send(b"p")
        game.expect(b"PAUSADO", mark)
        mark = game.send(b"r")
        game.expect(b"PRONTO PARA JOGAR?", mark)
        game.send(b"\r")
        game.collect(0.2)
        # Redimensionar uma partida pausa o jogo; a tela pequena não o avança.
        game.resize(16, 50)
        game.expect(b"70x24")
        mark = len(game.data)
        game.resize(24, 80)
        game.expect(b"PAUSADO", mark)
        game.send(b" ")
        mark = len(game.data)
        game.expect(b"FIM DE JOGO", mark, timeout=5)
        mark = game.send(b"r")
        game.expect(b"PRONTO PARA JOGAR?", mark)
        game.finish()
        game.close()
        terminals.remove(game)
        print("ok - speed, play, pause, arrows, restart, resize, loss and clean quit")

        # Q funciona mesmo quando o terminal começa menor que o tabuleiro.
        small = Terminal(command(["--seed", "0"], True), rows=12, columns=40)
        terminals.append(small)
        small.expect(b"70x24")
        small.finish()
        small.close()
        terminals.remove(small)
        print("ok - undersized terminal remains usable")

        for key in (b"\x1b", b"\x03"):
            game = Terminal(command(["--seed", "4294967295"], True))
            terminals.append(game)
            game.expect(b"PRONTO PARA JOGAR?")
            game.finish(key)
            game.close()
            terminals.remove(game)
        print("ok - Esc and Ctrl-C restore cursor and terminal mode")
    finally:
        for terminal in terminals:
            terminal.close()
        if args.docker:
            # Somente o container nomeado por esta execução pode ser removido.
            subprocess.run(["docker", "rm", "-f", name],
                           stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL,
                           timeout=10)
    print("PASS: terminal smoke")


if __name__ == "__main__":
    main()
