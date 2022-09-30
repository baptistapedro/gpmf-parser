FROM fuzzers/afl:2.52 as builder

RUN apt update -y && apt install -y build-essential clang cmake
RUN mkdir /gpmf-parser
WORKDIR /gpmf-parser
COPY . .
RUN mkdir build
WORKDIR ./build
RUN CC=afl-clang CXX=afl-clang++ cmake -DBUILD_SHARED_LIBS=1 ..
RUN make

FROM fuzzers/afl:2.52 

COPY --from=builder /gpmf-parser/samples /testsuite/
COPY --from=builder /gpmf-parser/build/gpmf-parser /

ENTRYPOINT ["afl-fuzz", "-i", "/testsuite", "-o", "/out"]
CMD ["/gpmf-parser", "@@"] 
