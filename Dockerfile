FROM fuzzers/afl:2.52 as builder

RUN apt update -y && apt install -y build-essential clang cmake
RUN mkdir /gpmf-parser
WORKDIR /gpmf-parser
COPY . .
RUN cmake -DBUILD_SHARED_LIBS=1 .
RUN make
WORKDIR ./demo

RUN afl-clang -g -c GPMF_demo.c
RUN afl-clang -g -c GPMF_mp4reader.c
RUN afl-clang -g -c GPMF_print.c
RUN afl-clang -g -c ../GPMF_parser.c
RUN afl-clang -g -c ../GPMF_utils.c
RUN afl-clang -o gpmfdemo GPMF_demo.o GPMF_parser.o GPMF_utils.o GPMF_mp4reader.o GPMF_print.o

FROM fuzzers/afl:2.52 

COPY --from=builder /gpmf-parser/samples /testsuite/
COPY --from=builder /gpmf-parser/demo/gpmfdemo /

ENTRYPOINT ["afl-fuzz", "-i", "/testsuite", "-o", "/dev/null"]
CMD ["/gpmfdemo", "@@"] 
