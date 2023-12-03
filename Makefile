.PHONY: all check munge status dist src-dist ttf-dist norm check-harder pre-patch clean

# Release version
VERSION = 3.001
# Snapshot version
SNAPSHOT =
# Initial source directory, assumed read-only
SRCDIR  = src
# Directory where temporary files live
TMPDIR  = tmp
# Directory where final files are created
BUILDDIR  = build
# Directory where final archives are created
DISTDIR = dist

# Release layout
DOCDIR = .
SCRIPTSDIR = scripts
TTFDIR = ttf
RESOURCEDIR = resources

ifeq "$(SNAPSHOT)" ""
ARCHIVEVER = $(VERSION)
else
ARCHIVEVER = $(VERSION)-$(SNAPSHOT)
endif

SRCARCHIVE  = brutalist-fonts-$(ARCHIVEVER)
ARCHIVE = brutalist-fonts-ttf-$(ARCHIVEVER)

ARCHIVEEXT = .zip .tar.bz2
SUMEXT     = .zip.md5 .tar.bz2.md5 .tar.bz2.sha512

OLDSTATUS   = $(DOCDIR)/status.txt
BLOCKS      = $(RESOURCEDIR)/Blocks.txt
UNICODEDATA = $(RESOURCEDIR)/UnicodeData.txt
FC-LANG     = $(RESOURCEDIR)/fc-lang

GENERATE    = $(SCRIPTSDIR)/generate.pe
TTPOSTPROC  = $(SCRIPTSDIR)/ttpostproc.pl
UNICOVER    = $(SCRIPTSDIR)/unicover.pl
LANGCOVER   = $(SCRIPTSDIR)/langcover.pl
STATUS	    = $(SCRIPTSDIR)/status.pl
PROBLEMS    = $(SCRIPTSDIR)/problems.pl
NORMALIZE   = $(SCRIPTSDIR)/sfdnormalize.pl

SRC      := $(wildcard $(SRCDIR)/*.sfd)
SFDFILES := $(patsubst $(SRCDIR)/%, %, $(SRC))
SFD  := $(patsubst $(SRCDIR)/%.sfd, $(TMPDIR)/%.sfd, $(SRC))
NORMSFD := $(patsubst %, %.norm, $(SFD))
TTF  := $(patsubst $(TMPDIR)/%.sfd, $(BUILDDIR)/%.ttf, $(SFD))

STATICDOC := $(addprefix $(DOCDIR)/, LICENSE README.md)
STATICSRCDOC := $(addprefix $(DOCDIR)/, BUILDING.md)
GENDOC = unicover.txt langcover.txt status.txt

all : $(TTF)

$(TMPDIR)/%.sfd: $(SRCDIR)/%.sfd
	@echo "[1] $< => $@"
	install -d $(dir $@)
	sed "s@\(Version:\? \)\(0\.[0-9]\+\.[0-9]\+\|[1-9][0-9]*\.[0-9]\+\)@\1$(VERSION)@" $< > $@
	touch -r $< $@

$(BUILDDIR)/%.ttf: $(TMPDIR)/%.sfd
	@echo "[3] $< => $@"
	install -d $(dir $@)
	$(GENERATE) $<
	ttfautohint $<.ttf $@
	$(TTPOSTPROC) $@
	$(RM) $@~
	touch -r $< $@

$(BUILDDIR)/status.txt: $(SFD)
	@echo "[4] => $@"
	install -d $(dir $@)
	$(STATUS) $(VERSION) $(OLDSTATUS) $(SFD) > $@

$(BUILDDIR)/unicover.txt: $(patsubst %, $(TMPDIR)/%.sfd, BrutalistMono-Regular)
	@echo "[5] => $@"
	install -d $(dir $@)
	$(UNICOVER) $(UNICODEDATA) $(BLOCKS) \
	            $(TMPDIR)/BrutalistMono-Regular.sfd "Sans Mono" > $@

$(BUILDDIR)/langcover.txt: $(patsubst %, $(TMPDIR)/%.sfd, BrutalistMono-Regular)
	@echo "[6] => $@"
	install -d $(dir $@)
ifeq "$(FC-LANG)" ""
	touch $@
else
	$(LANGCOVER) $(FC-LANG) \
	             $(TMPDIR)/BrutalistMono-Regular.sfd "Sans Mono" > $@
endif

$(BUILDDIR)/Makefile: Makefile
	@echo "[7] => $@"
	install -d $(dir $@)
	sed -e "s+^VERSION\([[:space:]]*\)=\(.*\)+VERSION = $(VERSION)+g"\
	    -e "s+^SNAPSHOT\([[:space:]]*\)=\(.*\)+SNAPSHOT = $(SNAPSHOT)+g" < $< > $@
	touch -r $< $@

$(TMPDIR)/$(SRCARCHIVE): $(addprefix $(BUILDDIR)/, $(GENDOC) Makefile) $(SFD)
	@echo "[8] => $@"
	install -d -m 0755 $@/$(SCRIPTSDIR)
	install -d -m 0755 $@/$(SRCDIR)
	install -d -m 0755 $@/$(DOCDIR)
	install -p -m 0644 $(BUILDDIR)/Makefile $@
	install -p -m 0755 $(GENERATE) $(TTPOSTPROC) $(NORMALIZE) \
	                   $(UNICOVER) $(LANGCOVER) $(STATUS) $(PROBLEMS) \
	                   $@/$(SCRIPTSDIR)
	install -p -m 0644 $(SFD) $@/$(SRCDIR)
	install -p -m 0644 $(addprefix $(BUILDDIR)/, $(GENDOC)) \
	                   $(STATICDOC) $(STATICSRCDOC) $@/$(DOCDIR)

$(TMPDIR)/$(ARCHIVE): $(TTF) $(STATUS)
	@echo "[8] => $@"
	install -d -m 0755 $@/$(TTFDIR)
	install -d -m 0755 $@/$(DOCDIR)
	install -p -m 0644 $(TTF) $@/$(TTFDIR)
	install -p -m 0644 $(addprefix $(BUILDDIR)/, $(GENDOC)) \
	                   $(STATICDOC) $@/$(DOCDIR)

$(DISTDIR)/%.zip: $(TMPDIR)/%
	@echo "[9] => $@"
	install -d $(dir $@)
	(cd $(TMPDIR); zip -rv $(abspath $@) $(notdir $<))

$(DISTDIR)/%.tar.bz2: $(TMPDIR)/%
	@echo "[9] => $@"
	install -d $(dir $@)
	(cd $(TMPDIR); tar cjvf $(abspath $@) $(notdir $<))

%.md5: %
	@echo "[10] => $@"
	(cd $(dir $<); md5sum -b $(notdir $<) > $(abspath $@))

%.sha512: %
	@echo "[10] => $@"
	(cd $(dir $<); sha512sum -b $(notdir $<) > $(abspath $@))

%.sfd.norm: %.sfd
	@echo "[11] $< => $@"
	$(NORMALIZE) $<
	touch -r $< $@

check : $(NORMSFD)
	for sfd in $^ ; do \
	echo "[12] Checking $$sfd" ;\
	$(PROBLEMS)  $$sfd ;\
	done

munge: $(NORMSFD)
	for sfd in $(SFDFILES) ; do \
	echo "[13] $(TMPDIR)/$$sfd.norm => $(SRCDIR)/$$sfd" ;\
	cp $(TMPDIR)/$$sfd.norm $(SRCDIR)/$$sfd ;\
	done

status : $(addprefix $(BUILDDIR)/, $(GENDOC))

dist : src-dist ttf-dist

src-dist :  $(addprefix $(DISTDIR)/$(SRCARCHIVE),  $(ARCHIVEEXT) $(SUMEXT))

ttf-dist : $(addprefix $(DISTDIR)/$(ARCHIVE), $(ARCHIVEEXT) $(SUMEXT))

norm : $(NORMSFD)

check-harder : clean check

pre-patch : munge clean

clean :
	$(RM) -r $(TMPDIR) $(BUILDDIR) $(DISTDIR)
