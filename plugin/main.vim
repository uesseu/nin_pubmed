scriptencoding utf-8
" nin_pubmed
" Last Change:	2020 Dec 11
" Maintainer:	Ninja <sheepwing@kyudai.jp>
" License:	Mit licence
if exists('g:nin_pubmed')
  finish
endif
let g:nin_pubmed = 1

let s:save_cpo = &cpo
set cpo&vim
command! -nargs=1 BioWord call BioWord(<f-args>)
command! BioNext call BioNext()
command! BioAbs call BioAbs()

python3 << init
import vim
from Bio import Entrez
from typing import cast, Generator, List
from itertools import product
from chainiter import ChainIter, chain_product
from logging import getLogger
Entrez.email = vim.eval('g:nin_pubmed#email')
logger = getLogger()

class BioGetter:
    def __init__(self):
        self.retstart = 0
        self.retmax = 100
        self.num_list = []
        self.current_num = None

    def next_abs(self, db: str = 'pubmed') -> str:
        self.current_num = self.num_list.pop(0)
        handle = Entrez.efetch(db=db, id=self.current_num,
                               rettype='abstract', retmode='text')
        print(f'Index of {len(self.num_list)}')
        with open(f'Abst-{self.current_num}', 'w') as fp:
            fp.write(handle.read())
        handle.close()

    def setup_word(self, term: str):
        self.term = term
        self.retstart = 0
        self.retmax = 100

    def get_list(self, db: str = 'pubmed') -> list:
        handle = Entrez.esearch(db=db, term=self.term,
                                retstart=self.retstart,
                                retmax=self.retmax)
        record = Entrez.read(handle)
        self.num_list = record['IdList']
        handle.close()
        print(record['Count'])
        self.retstart += 100
        self.retmax += 100
biogetter = BioGetter()
init


function! BioWord (word)
python3 << getbl
biogetter.setup_word(vim.eval('a:word'))
getbl
endfunction

function! BioNext ()
python3 << getbl
biogetter.get_list()
getbl
endfunction

function! BioAbs ()
python3 << getbl
biogetter.next_abs()
vim.command(f'e Abst-{biogetter.current_num}')
getbl
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
