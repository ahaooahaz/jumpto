ifeq ($(OS), Windows_NT)
PLATFORM = windows
SHELL = cmd.exe
# Windows
TARGETS = $(shell dir cmd /b)
GO_SRCS = $(shell for /r . %%i in (*.go) do @echo %%i)
REPO = github.com/ahaooahaz/rtcvpub
BUILT_TS ?= $(shell echo %date:~0,4%%date:~5,2%%date:~8,2%%time:~0,2%%time:~3,2%%time:~6,2%)
BINARY_SUFFIX = .exe

else
UNAME_S := $(shell uname -s)
REPO = $(shell git remote -v | grep '^origin\s.*(fetch)$$' | awk '{print $$2}' | sed -E 's/^.*(\/\/|@)//;s/\.git$$//' | sed 's/:/\//g')
TIMESTAMP = $(shell date +%s)
BUILT_TS ?= $(shell TZ='Asia/Shanghai' date '+%Y-%m-%d %H:%M:%S')

GO_SRCS = $(shell find  .  -type f -regex  ".*.go$$")
TARGETS = $(shell ls cmd)
ifeq ($(UNAME_S), Linux)
PLATFORM = linux
else ifeq ($(UNAME_S), Darwin)
PLATFORM = darwin
endif
endif
VENDOR_LIST = go.mod go.sum

SUPPORT_PLATFORMS := linux darwin
SUPPORT_ARCHS := amd64 arm64
ALL_TARGETS := $(foreach t,$(TARGETS),$(foreach p,$(SUPPORT_PLATFORMS),$(foreach a,$(SUPPORT_ARCHS),$(t)-$(p)-$(a))))

COMMIT_ID ?= $(shell git rev-parse --short HEAD)
BRANCH ?= $(shell git rev-parse --abbrev-ref HEAD)
VERSION ?= $(shell git describe --tags --always --dirty)

GO = go

LDFLAGS += -s -w
LDFLAGS += -X "$(REPO)/version.BuildTS=$(BUILT_TS)"
LDFLAGS += -X "$(REPO)/version.GitHash=$(COMMIT_ID)"
LDFLAGS += -X "$(REPO)/version.Version=$(VERSION)"
LDFLAGS += -X "$(REPO)/version.GitBranch=$(BRANCH)"

all: $(ALL_TARGETS)

$(TARGETS)-%: $(GO_SRCS) $(VENDOR_LIST)
	name=$(word 1,$(subst -, ,$@)); \
	platform=$(word 2,$(subst -, ,$@)); \
	arch=$(word 3,$(subst -, ,$@)); \
	echo "building $@ for $$platform/$$arch"; \
	${CGO_BUILD_OP} GOOS=$$platform GOARCH=$$arch $(GO) build -ldflags '$(LDFLAGS)' -tags='$(TAGS)' -o $@$(BINARY_SUFFIX) $(REPO)/cmd/$${name}/

test:
	go test ./... -coverprofile=${COVERAGE_REPORT} -covermode=atomic -tags='$(TAGS)'

clean:
ifeq ($(PLATFORM), windows)
# TODO: windows
	echo "skip for windows"
else
	-rm -rf $(ALL_TARGETS)
endif

.PHONY: all
