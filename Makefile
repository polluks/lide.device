PROJECT=lide.device
BUILDDIR=build
ROM=lide.rom
VERSION := $(shell git describe --tags --dirty | sed -r 's/^Release-//')

GIT_REF_NAME = $(shell git branch --show-current)
GIT_REF := "$(GIT_REF_NAME)-$(shell git rev-parse --short HEAD)"
BUILD_DATE := $(shell date  +"%d.%m.%Y")

export BUILD_DATE
export GIT_REF

CC=m68k-amigaos-gcc
CFLAGS+=-nostartfiles -nostdlib -mcpu=68000 -Wall -Wno-multichar -Wno-pointer-sign -Wno-attributes  -Wno-unused-value -s -Os -fomit-frame-pointer -DCDBOOT=1 -DNO_RDBLAST=1
CFLAGS+=-DGIT_REF=$(GIT_REF) -DBUILD_DATE=$(BUILD_DATE)
LDFLAGS=-lgcc -lc
AS=m68k-amigaos-as

ifeq ($(shell uname),Darwin)
GREP=ggrep
else
GREP=grep
endif

ifneq ($(VERSION),)
DISK=lide-update-$(VERSION).adf
DEVICE_VERSION=$(shell echo $(VERSION) | $(GREP) -oP '^(\w+-)?\K\d+')
DEVICE_REVISION=$(shell echo $(VERSION) | $(GREP) -oP '^(\w+-)?\d+\.\K\d+')
CFLAGS+=-DDEVICE_VERSION=$(DEVICE_VERSION) -DDEVICE_REVISION=$(DEVICE_REVISION)

export DEVICE_REVISION
export DEVICE_VERSION

else
DISK=lide-update.adf
endif

ifdef DEBUG
CFLAGS+= -DDEBUG=$(DEBUG)
LDFLAGS=-ldebug -lgcc -lc
.PHONY: $(PROJECT)
endif

ifdef NOTIMER
CFLAGS+= -DNOTIMER=1
.PHONY: $(PROJECT)
endif

ifdef SLOWXFER
CFLAGS+= -DSLOWXFER=1
.PHONY: $(PROJECT)
endif

ifdef SIMPLE_IDE
CFLAGS+= -DSIMPLE_IDE=1
.PHONY: $(PROJECT)
endif

.PHONY:	clean all lideflash disk lha rename/renamelide lidetool/lidetool

all:	$(ROM) \
		lideflash \
		rename/renamelide \
		lide-N2630-high.rom \
		lide-N2630-low.rom \
		AIDE-$(PROJECT)

OBJ = device.o \
      ata.o \
	  atapi.o \
	  scsi.o \
	  idetask.o \
	  lide_alib.o \
	  mounter.o \
	  debug.o

ASMOBJ = endskip.o

SRCS = $(OBJ:%.o=%.c)
SRCS += $(ASMOBJ:%.o=%.S)

$(PROJECT): $(SRCS)
	${CC} -o $@ $(CFLAGS) $(SRCS) $(LDFLAGS)

$(ROM): $(PROJECT)
	make -C bootrom

AIDE-$(PROJECT): $(SRCS)
	${CC} -o $@ $(CFLAGS) -DSIMPLE_IDE=1 $(SRCS) bootblock.S $(LDFLAGS)

lideflash/lideflash:
	make -C lideflash

lideflash: lideflash/lideflash

lidetool/lidetool:
	make -C lidetool

rename/renamelide:
	make -C rename

$(BUILDDIR)/AIDE-boot-$(VERSION).adf: AIDE-$(PROJECT)
	@make -C aide-boot
	@mv aide-boot/aide-boot.adf $@

disk:	$(BUILDDIR)/$(DISK) $(BUILDDIR)/AIDE-boot-$(VERSION).adf

$(BUILDDIR)/$(DISK): $(ROM) lideflash/lideflash rename/renamelide lidetool/lidetool AIDE-lide.device
	@mkdir -p $(BUILDDIR)
	cp $(ROM) build
	echo -n 'lideflash -I $(ROM)\n' > $(BUILDDIR)/startup-sequence
	xdftool $(BUILDDIR)/$(DISK) format lide-update + \
	                            boot install + \
	                            write $(ROM) + \
	                            write lidetool/lidetool lidetool + \
	                            write lideflash/lideflash lideflash + \
	                            write rename/renamelide renamelide + \
	                            makedir s + \
	                            write $(BUILDDIR)/startup-sequence s/startup-sequence + \
	                            makedir Expansion + \
	                            write info/Expansion.info Expansion.info + \
	                            write info/lide.device.info Expansion/lide.device.info + \
	                            write lide.device Expansion/lide.device + \
	                            write AIDE-lide.device AIDE-lide.device

$(BUILDDIR)/lide-update.lha: lideflash/lideflash $(ROM) rename/renamelide lidetool/lidetool lide.device info/lide.device.info AIDE-lide.device
	@mkdir -p $(BUILDDIR)
	cp $^ $(BUILDDIR)
	cd $(BUILDDIR) && lha -c ../$@ $(notdir $^) 

lha: $(BUILDDIR)/lide-update.lha 

lide-N2630-high.rom: $(ROM)
	srec_cat lide-word.rom -binary -split 2 0 1 -out $@ -binary

lide-N2630-low.rom:  $(ROM)
	srec_cat lide-word.rom -binary -split 2 1 1 -out $@ -binary

lide-tk-29F010.rom: $(ROM)
	@cat lide-atbus.rom lide-atbus.rom lide-atbus.rom lide-atbus.rom > $@

lide-tk-29F020.rom: lide-tk-29F010.rom
	@cat $< $< > $@

lide-tk-29F040.rom: lide-tk-29F020.rom
	@cat $< $< > $@

clean:
	-rm -f $(PROJECT)
	-rm -f AIDE-$(PROJECT)
	make -C bootrom clean
	make -C lideflash clean
	make -C lidetool clean
	make -C rename clean
	-rm -rf *.rom
	-rm -rf $(BUILDDIR)
	make -C aide-boot clean
