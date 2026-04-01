PREFIX ?= $(HOME)/.local
BINDIR ?= $(PREFIX)/bin
LIBDIR ?= $(PREFIX)/lib/worktree-fns

.PHONY: install test uninstall

test:
	./tests/run.zsh

install:
	install -d "$(BINDIR)" "$(LIBDIR)"
	/bin/rm -rf "$(LIBDIR)/bin" "$(LIBDIR)/completions" "$(LIBDIR)/functions"
	cp -R bin completions functions "$(LIBDIR)/"
	install -m 0644 README.md "$(LIBDIR)/README.md"
	install -m 0644 TODO.md "$(LIBDIR)/TODO.md"
	install -m 0644 worktree-fns.zsh "$(LIBDIR)/worktree-fns.zsh"
	ln -sf "$(LIBDIR)/bin/worktree-fns" "$(BINDIR)/worktree-fns"

uninstall:
	/bin/rm -rf "$(LIBDIR)" "$(BINDIR)/worktree-fns"
