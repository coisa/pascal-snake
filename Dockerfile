FROM frolvlad/alpine-fpc

ENV LANG C.UTF-8
ENV LC_ALL C.UTF-8

WORKDIR /app

COPY SnakeGame.pas /app

RUN fpc SnakeGame.pas

CMD ["./SnakeGame"]
