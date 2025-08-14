#!/usr/bin/zsh

cd modules/thirdparty/VexiiRiscv
sbt "Test/runMain vexiiriscv.Generate \
  --xlen 32 \
  --with-rvm --with-rvc --with-rva --with-rvf --with-rvd \
  --dual-issue --max-ipc \
  --with-btb --with-gshare --with-ras \
  --gshare-bytes 4 --btb-sets 256 --btb-hash-width 12 \
  --with-fetch-l1 --fetch-l1 \
  --fetch-l1-ways 2 --fetch-l1-sets 64 \
  --fetch-wishbone \
  --with-lsu-l1 --lsu-l1 \
  --lsu-l1-ways 2 --lsu-l1-sets 64 \
  --lsu-l1-wishbone \
  --fetch-l1-mem-data-width-min 256 \
  --lsu-l1-mem-data-width-min 256 \
  --fetch-l1-refill-count 2 \
  --lsu-l1-refill-count 2 \
  --lsu-l1-writeback-count 2 \
  --lsu-l1-store-buffer-slots 8 \
  --with-lsu-bypass \
  --without-mmu \
  --reset-vector 0 --lsu-wishbone "

cp VexiiRiscv.v ../
cd ../../../
