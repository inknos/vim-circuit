VADER := test/vader.vim
VINT  := vint

.PHONY: test lint check

test: $(VADER)
	vim -Nu test/vimrc -c 'Vader! test/*.vader'

lint:
	$(VINT) autoload/ plugin/

check: lint test
