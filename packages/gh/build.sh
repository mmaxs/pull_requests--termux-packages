TERMUX_PKG_HOMEPAGE=https://cli.github.com/
TERMUX_PKG_DESCRIPTION="GitHub’s official command line tool"
TERMUX_PKG_LICENSE="MIT"
TERMUX_PKG_MAINTAINER="Krishna kanhaiya @kcubeterm"
TERMUX_PKG_VERSION="2.14.4"
TERMUX_PKG_SRCURL=https://github.com/cli/cli/archive/v${TERMUX_PKG_VERSION}.tar.gz
TERMUX_PKG_SHA256=be93380e5a7f2822a1bfeff80f23231ee72ca297b9bc05bba0a1c688f9f53ccf
TERMUX_PKG_AUTO_UPDATE=true

termux_step_make() {
	termux_setup_golang

	cd "$TERMUX_PKG_SRCDIR"
	(
		unset GOOS GOARCH CGO_LDFLAGS
		unset CC CXX CFLAGS CXXFLAGS LDFLAGS
		go run ./cmd/gen-docs --man-page --doc-path \
			$TERMUX_PKG_MASSAGEDIR/$TERMUX_PREFIX/share/man/man1/
	)
	export GOPATH=$TERMUX_PKG_BUILDDIR
	mkdir -p "$GOPATH"/src/github.com/cli/

	cp -a "$TERMUX_PKG_SRCDIR" "$GOPATH"/src/github.com/cli/cli
	cd "$GOPATH"/src/github.com/cli/cli/cmd/gh
	go get -d -v
	go build -ldflags="-X github.com/cli/cli/v${TERMUX_PKG_VERSION%%.*}/internal/build.Version=$TERMUX_PKG_VERSION"
}

termux_step_make_install() {
	install -Dm700 -t "$TERMUX_PKG_MASSAGEDIR/$TERMUX_PREFIX"/bin \
		"$GOPATH"/src/github.com/cli/cli/cmd/gh/gh
	install -Dm600 -t "$TERMUX_PKG_MASSAGEDIR/$TERMUX_PREFIX"/share/doc/gh/ \
		"$TERMUX_PKG_SRCDIR"/docs/*
}

termux_step_create_debscripts() {
	cat <<-EOF >./postinst
		#!${TERMUX_PREFIX}/bin/sh
		mkdir -p ${TERMUX_PREFIX}/share/bash-completion/completions
		mkdir -p ${TERMUX_PREFIX}/share/zsh/site-functions
		mkdir -p ${TERMUX_PREFIX}/share/fish/vendor_completions.d
		gh completion -s bash > ${TERMUX_PREFIX}/share/bash-completion/completions/gh.bash
		gh completion -s zsh > ${TERMUX_PREFIX}/share/zsh/site-functions/_gh
		gh completion -s fish > ${TERMUX_PREFIX}/share/fish/vendor_completions.d/gh.fish
	EOF

	cat <<-EOF >./prerm
		#!${TERMUX_PREFIX}/bin/sh
		rm -f ${TERMUX_PREFIX}/share/bash-completion/completions/gh.bash
		rm -f ${TERMUX_PREFIX}/share/zsh/site-functions/_gh
		rm -f ${TERMUX_PREFIX}/share/fish/vendor_completions.d/gh.fish
	EOF
}
