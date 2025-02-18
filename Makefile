GOOGLE_INCLUDE=$(shell pkg-config protobuf --variable=includedir)/google/protobuf

.PHONY: build
build: ## Build
	@dune build @install

.PHONY: clean
clean: ## Clean
	@dune clean

.PHONY: test
test: build
test: ## Run tests
	@dune runtest --force

.PHONY: install
install: build ## Install
	@dune install

.PHONY: uninstall
uninstall: build ## uninstall
	@dune uninstall

%: %.proto
	protoc --experimental_allow_proto3_optional -I $(dir $<) $< -o/dev/stdout | protoc --experimental_allow_proto3_optional --decode google.protobuf.FileDescriptorSet $(GOOGLE_INCLUDE)/descriptor.proto

src/spec/descriptor.ml: build
	protoc "--plugin=protoc-gen-ocaml=_build/default/src/plugin/protoc_gen_ocaml.exe" \
	  -I /usr/include \
	  --ocaml_out=src/spec/. \
	  $(GOOGLE_INCLUDE)/descriptor.proto

src/spec/plugin.ml: build
	protoc "--plugin=protoc-gen-ocaml=_build/default/src/plugin/protoc_gen_ocaml.exe" \
	  -I /usr/include \
	  --ocaml_out=src/spec/. \
	  $(GOOGLE_INCLUDE)/compiler/plugin.proto

src/spec/options.ml: build
	protoc "--plugin=protoc-gen-ocaml=_build/default/src/plugin/protoc_gen_ocaml.exe" \
	  -I src/spec -I /usr/include \
	  --ocaml_out=src/spec/. \
	  src/spec/options.proto
.PHONY: bootstrap
bootstrap: src/spec/descriptor.ml src/spec/plugin.ml src/spec/options.ml



.PHONY: doc
doc: ## Build documentation
	dune build @doc

gh-pages: doc ## Publish documentation
	git clone `git config --get remote.origin.url` .gh-pages --reference .
	git -C .gh-pages checkout --orphan gh-pages
	git -C .gh-pages reset
	git -C .gh-pages clean -dxf
	cp  -r _build/default/_doc/_html/* .gh-pages
	git -C .gh-pages add .
	git -C .gh-pages config user.email 'docs@ocaml-protoc-plugin'
	git -C .gh-pages commit -m "Update documentation"
	git -C .gh-pages push origin gh-pages -f
	rm -rf .gh-pages

.PHONY: help
help: ## Show this help
	@grep -h -E '^[.a-zA-Z_-]+:.*## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'
