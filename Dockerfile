FROM fuzzers/afl:2.52 as builder

RUN apt-get update
RUN apt install -y build-essential wget git clang cmake
RUN git clone https://github.com/gopro/gpmf-parser.git
WORKDIR /gpmf-parser
RUN cmake -DBUILD_SHARED_LIBS=1 .
RUN make
#RUN make install
WORKDIR ./demo

RUN afl-clang -g -c GPMF_demo.c
RUN afl-clang -g -c GPMF_mp4reader.c
RUN afl-clang -g -c GPMF_print.c
RUN afl-clang -g -c ../GPMF_parser.c
RUN afl-clang -g -c ../GPMF_utils.c
RUN afl-clang -o gpmfdemo GPMF_demo.o GPMF_parser.o GPMF_utils.o GPMF_mp4reader.o GPMF_print.o

#RUN git clone https://github.com/baptistapedro/mp4corpus.git
RUN mkdir /in
#RUN cp ./mp4corpus/corpus/*.mp4 /in/
#RUN rm -rf ./mp4corpus/
RUN git clone https://github.com/strongcourage/fuzzing-corpus.git
RUN cp ./fuzzing-corpus/mp4/mozilla/MPEG4.mp4 /in/
RUN cp ./fuzzing-corpus/mp4/mozilla/aac-sample.mp4 /in/
RUN cp ./fuzzing-corpus/mp4/mozilla/red-green.mp4 /in/

FROM fuzzers/afl:2.52 

RUN apt-get update && apt-get install -y cmake git make
COPY --from=builder /in/* /testsuite/
COPY --from=builder /gpmf-parser/demo/gpmfdemo /

# Add GPMF structure

RUN git clone https://github.com/gopro/gpmf-write.git
WORKDIR /gpmf-write
RUN cmake .
RUN make
#RUN make install
RUN ./gpmf-writer /testsuite/aac-sample.mp4
RUN ./gpmf-writer /testsuite/MPEG4.mp4
RUN ./gpmf-writer /testsuite/red-green.mp4    #sample3.mp4
#RUN ./gpmf-writer /testsuite/sample2.mp4    #sample2.mp4

ENTRYPOINT ["afl-fuzz", "-i", "/testsuite", "-o", "/gpmfparser_Out"]
CMD ["/gpmfdemo", "@@"] 
