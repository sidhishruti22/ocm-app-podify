NAME                = ocm-app-podify
PROVIDER            ?= sidhishruti22
COMPONENT           = github.com/$(PROVIDER)/$(NAME)
OCI_REPO            ?= ghcr.io/sidhishruti22/ocm-app-ex-podify

CHILD_COMPONENTS    ?= backend frontend 
GEN_DIRS            := $(addprefix $(CHILD_COMPONENTS),/gen)

VERSION             := $(shell git describe --tags --exact-match 2>/dev/null|| echo "$$(cat VERSION)-dev")
COMMIT              = $(shell git rev-parse HEAD)
EFFECTIVE_VERSION   = $(VERSION)-$(COMMIT)

OCM = ocm

define make-child

.PHONY: $1
$1: $1/clean $1/gen $1/ca $1/push

$1/gen:
	mkdir -p $1/gen

$1/ca:
	$(OCM) create componentarchive github.com/$(PROVIDER)/$1 $(shell cat $1/VERSION) \
		--provider $(PROVIDER) --file $1/component-archive --scheme ocm.software/v3alpha1  -f
	$(OCM) add resources $1/component-archive $1/resources.yaml

$1/push: $1/component-archive
	$(OCM) transfer component -f $1/component-archive $(OCI_REPO)

$1/clean:
	rm -rf $1/component-archive

endef

.PHONY: all sign
all: $(CHILD_COMPONENTS) push

keys:
	$(OCM) create rsakeypair key.priv key.pub

sign:
	$(OCM) sign component -s skarlso -K key.priv --repo $(OCI_REPO) $(COMPONENT)

ca: component-archive
	$(OCM) create componentarchive -f $(COMPONENT) $(VERSION) --provider $(PROVIDER) -F component-archive --scheme ocm.software/v3alpha1
	$(OCM) add references component-archive references.yaml

push: ca
	$(OCM) transfer component -f --copy-resources --recursive --lookup $(OCI_REPO) component-archive $(OCI_REPO)

gen:
	@mkdir -p component-archive

clean:
	rm -rf component-archive

clean-all: clean $(CHILD_COMPONENTS).clean

$(foreach cdir,$(CHILD_COMPONENTS),$(eval $(call make-child,$(cdir))))
