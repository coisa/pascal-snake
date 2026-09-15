"""Black-box SDL lifecycle, CLI and rendered-frame checks, using only stdlib."""

import argparse
import os
from pathlib import Path
import struct
import subprocess
import tempfile


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("executable", nargs="?", default="./build/SnakeGame")
    args = parser.parse_args()
    environment = {**os.environ, "SDL_VIDEODRIVER": "dummy", "SDL_AUDIODRIVER": "dummy"}

    def run(arguments, expected=0, extra_env=None):
        result = subprocess.run([args.executable, *arguments],
                                env={**environment, **(extra_env or {})},
                                capture_output=True, timeout=20)
        assert result.returncode == expected, (arguments, result.returncode, result.stderr)
        assert b"Access violation" not in result.stderr
        assert b"Range check error" not in result.stderr
        return result

    help_text = run(["--help"]).stdout
    assert b"Pascal Edition" in help_text and b"\x1b" not in help_text
    for arguments in (["--unknown"], ["--seed"], ["--seed", "4294967296"],
                      ["--seed", "-1"], ["--seed", "+1"], ["--seed", "0x10"],
                      ["--seed", ""], ["--snapshot", ""], ["--scene", "bad"],
                      ["--scene", "menu"], ["--self-test", "--no-audio"]):
        run(arguments, 2)
    for _ in range(3):
        assert b"PASS graphical SDL replay" in run(["--self-test"]).stdout
    assert b"PASS graphical SDL replay" in run(
        ["--self-test"], extra_env={"SDL_AUDIODRIVER": "unavailable-driver"}).stdout
    print("ok - graphical CLI, repeated lifecycle, SDL replay and audio-unavailable fallback")

    # All artifacts are scoped to an automatically cleaned project build directory.
    Path("build").mkdir(exist_ok=True)
    with tempfile.TemporaryDirectory(prefix="desktop-", dir="build") as directory:
        root = Path(directory)
        frames = []
        for scene in ("menu", "play", "pause", "over", "win"):
            output = root / f"{scene}.bmp"
            run(["--seed", "42", "--no-audio", "--snapshot", str(output), "--scene", scene])
            data = output.read_bytes()
            assert data[:2] == b"BM", "renderer must produce a BMP"
            width, height = struct.unpack_from("<ii", data, 18)
            assert (width, height) == (1200, 800), (width, height)
            offset = struct.unpack_from("<I", data, 10)[0]
            pixels = data[offset:]
            assert len(pixels) == width * height * 4
            colors = {pixels[i:i + 3] for i in range(0, len(pixels), 4)}
            assert len(colors) > 80, "frame is blank or missing visual content"
            assert b"\x78\xf9\xa9" in colors, "mint game UI missing"
            frames.append(pixels)
        assert len(set(frames)) == 5, "phase overlays must render distinct frames"
        missing_font = run(["--snapshot", str(root / "error.bmp")], 1,
                           {"SNAKE_FONT": str(root / "missing.ttf")})
        assert b"Could not open font" in missing_font.stderr
        invalid_video = run(["--snapshot", str(root / "error.bmp")], 1,
                            {"SDL_VIDEODRIVER": "unavailable-driver"})
        assert b"Video initialization failed" in invalid_video.stderr
        run(["--snapshot", str(root / "missing" / "error.bmp")], 1)
    print("ok - five rendered states, frame content and clean initialization/output failures")
    print("PASS: desktop smoke")


if __name__ == "__main__":
    main()
