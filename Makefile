.PHONY: all check munge full lgc ttf full-ttf lgc-ttf status dist src-dist full-dist lgc-dist norm check-harder pre-patch clean

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
FULLARCHIVE = brutalist-fonts-ttf-$(ARCHIVEVER)
LGCARCHIVE  = brutalist-lgc-fonts-ttf-$(ARCHIVEVER)

ARCHIVEEXT = .zip .tar.bz2
SUMEXT     = .zip.md5 .tar.bz2.md5 .tar.bz2.sha512

OLDSTATUS   = $(DOCDIR)/status.txt
BLOCKS      = $(RESOURCEDIR)/Blocks.txt
UNICODEDATA = $(RESOURCEDIR)/UnicodeData.txt
FC-LANG     = $(RESOURCEDIR)/fc-lang

GENERATE    = $(SCRIPTSDIR)/generate.pe
TTPOSTPROC  = $(SCRIPTSDIR)/ttpostproc.pl
LGC         = $(SCRIPTSDIR)/lgc.pe
UNICOVER    = $(SCRIPTSDIR)/unicover.pl
LANGCOVER   = $(SCRIPTSDIR)/langcover.pl
STATUS	    = $(SCRIPTSDIR)/status.pl
PROBLEMS    = $(SCRIPTSDIR)/problems.pl
NORMALIZE   = $(SCRIPTSDIR)/sfdnormalize.pl
NARROW      = $(SCRIPTSDIR)/narrow.pe

SRC      := $(wildcard $(SRCDIR)/*.sfd)
SFDFILES := $(patsubst $(SRCDIR)/%, %, $(SRC))
FULLSFD  := $(patsubst $(SRCDIR)/%.sfd, $(TMPDIR)/%.sfd, $(SRC))
NORMSFD  := $(patsubst %, %.norm, $(FULLSFD))
MATSHSFD := $(wildcard $(SRCDIR)/*Math*.sfd)
LGCSRC   := $(filter-out $(MATSHSFD),$(SRC))
LGCSFD   := $(patsubst $(SRCDIR)/Brutalist%.sfd, $(TMPDIR)/BrutalistLGC%.sfd, $(LGCSRC))
FULLTTF  := $(patsubst $(TMPDIR)/%.sfd, $(BUILDDIR)/%.ttf, $(FULLSFD))
LGCTTF   := $(patsubst $(TMPDIR)/%.sfd, $(BUILDDIR)/%.ttf, $(LGCSFD))

FONTCONF     := $(wildcard $(FONTCONFDIR)/*.conf)
FONTCONFLGC  := $(wildcard $(FONTCONFDIR)/*lgc*.conf)
FONTCONFFULL := $(filter-out $(FONTCONFLGC), $(FONTCONF))

STATICDOC := $(addprefix $(DOCDIR)/, LICENSE README.md)
STATICSRCDOC := $(addprefix $(DOCDIR)/, BUILDING.md)
GENDOCFULL = unicover.txt langcover.txt status.txt
GENDOCLGC  = unicover-lgc.txt langcover-lgc.txt

#disable building lgc fonts
#all : full lgc
all : full

$(TMPDIR)/%.sfd: $(SRCDIR)/%.sfd
	@echo "[1] $< => $@"
	install -d $(dir $@)
	sed "s@\(Version:\? \)\(0\.[0-9]\+\.[0-9]\+\|[1-9][0-9]*\.[0-9]\+\)@\1$(VERSION)@" $< > $@
	touch -r $< $@

$(TMPDIR)/BrutalistLGCMathTeXGyre.sfd: $(TMPDIR)/BrutalistMathTeXGyre.sfd
	@echo "[2] skipping $<"

$(TMPDIR)/BrutalistLGC%.sfd: $(TMPDIR)/Brutalist%.sfd
	@echo "[2] $< => $@"
	sed -e 's,FontName: Brutalist,FontName: BrutalistLGC,'\
	    -e 's,FullName: Brutalist,FullName: Brutalist LGC,'\
	    -e 's,FamilyName: Brutalist,FamilyName: Brutalist LGC,'\
	    -e 's,"Brutalist \(\(Sans\|Serif\)*\( Condensed\| Mono\)*\( Bold\)*\( Oblique\|Italic\)*\)","Brutalist LGC \1",g' < $< > $@
	@echo "Stripping unwanted glyphs from $@"
	$(LGC) $@
	touch -r $< $@

$(BUILDDIR)/BrutalistLGCMathTeXGyre.ttf: $(TMPDIR)/BrutalistLGCMathTeXGyre.sfd
	@echo "[3] skipping $<"

$(BUILDDIR)/%.ttf: $(TMPDIR)/%.sfd
	@echo "[3] $< => $@"
	install -d $(dir $@)
	$(GENERATE) $<
	ttfautohint $<.ttf $@
	$(TTPOSTPROC) $@
	$(RM) $@~
	touch -r $< $@

$(BUILDDIR)/status.txt: $(FULLSFD)
	@echo "[4] => $@"
	install -d $(dir $@)
	$(STATUS) $(VERSION) $(OLDSTATUS) $(FULLSFD) > $@

$(BUILDDIR)/unicover.txt: $(patsubst %, $(TMPDIR)/%.sfd, BrutalistMono)
	@echo "[5] => $@"
	install -d $(dir $@)
	$(UNICOVER) $(UNICODEDATA) $(BLOCKS) \
	            $(TMPDIR)/BrutalistMono.sfd "Sans Mono" > $@

$(BUILDDIR)/unicover-lgc.txt: $(patsubst %, $(TMPDIR)/%.sfd, BrutalistLGCMono)
	@echo "[5] => $@"
	install -d $(dir $@)
	$(UNICOVER) $(UNICODEDATA) $(BLOCKS) \
	            $(TMPDIR)/BrutalistLGCMono.sfd "Sans Mono" > $@

$(BUILDDIR)/langcover.txt: $(patsubst %, $(TMPDIR)/%.sfd, BrutalistMono)
	@echo "[6] => $@"
	install -d $(dir $@)
ifeq "$(FC-LANG)" ""
	touch $@
else
	$(LANGCOVER) $(FC-LANG) \
	             $(TMPDIR)/BrutalistMono.sfd "Sans Mono" > $@
endif

$(BUILDDIR)/langcover-lgc.txt: $(patsubst %, $(TMPDIR)/%.sfd, BrutalistLGCMono)
	@echo "[6] => $@"
	install -d $(dir $@)
ifeq "$(FC-LANG)" ""
	touch $@
else
	$(LANGCOVER) $(FC-LANG) \
	             $(TMPDIR)/BrutalistLGCMono.sfd "Sans Mono" > $@
endif

$(BUILDDIR)/Makefile: Makefile
	@echo "[7] => $@"
	install -d $(dir $@)
	sed -e "s+^VERSION\([[:space:]]*\)=\(.*\)+VERSION = $(VERSION)+g"\
	    -e "s+^SNAPSHOT\([[:space:]]*\)=\(.*\)+SNAPSHOT = $(SNAPSHOT)+g" < $< > $@
	touch -r $< $@

$(TMPDIR)/$(SRCARCHIVE): $(addprefix $(BUILDDIR)/, $(GENDOCFULL) Makefile) $(FULLSFD)
	@echo "[8] => $@"
	install -d -m 0755 $@/$(SCRIPTSDIR)
	install -d -m 0755 $@/$(SRCDIR)
	install -d -m 0755 $@/$(DOCDIR)
	install -p -m 0644 $(BUILDDIR)/Makefile $@
	install -p -m 0755 $(GENERATE) $(TTPOSTPROC) $(LGC) $(NORMALIZE) \
	                   $(UNICOVER) $(LANGCOVER) $(STATUS) $(PROBLEMS) \
	                   $@/$(SCRIPTSDIR)
	install -p -m 0644 $(FULLSFD) $@/$(SRCDIR)
	install -p -m 0644 $(addprefix $(BUILDDIR)/, $(GENDOCFULL)) \
	                   $(STATICDOC) $(STATICSRCDOC) $@/$(DOCDIR)

$(TMPDIR)/$(FULLARCHIVE): full
	@echo "[8] => $@"
	install -d -m 0755 $@/$(TTFDIR)
	install -d -m 0755 $@/$(DOCDIR)
	install -p -m 0644 $(FULLTTF) $@/$(TTFDIR)
	install -p -m 0644 $(addprefix $(BUILDDIR)/, $(GENDOCFULL)) \
	                   $(STATICDOC) $@/$(DOCDIR)

$(TMPDIR)/$(LGCARCHIVE): lgc
	@echo "[8] => $@"
	install -d -m 0755 $@/$(TTFDIR)
	install -d -m 0755 $@/$(DOCDIR)
	install -p -m 0644 $(LGCTTF) $@/$(TTFDIR)
	install -p -m 0644 $(addprefix $(BUILDDIR)/, $(GENDOCLGC)) \
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

full : $(FULLTTF) $(addprefix $(BUILDDIR)/, $(GENDOCFULL))

lgc : $(LGCTTF) $(addprefix $(BUILDDIR)/, $(GENDOCLGC))

ttf : full-ttf -ttf lgc-ttf

full-ttf : $(FULLTTF)

lgc-ttf : $(LGCTTF)

status : $(addprefix $(BUILDDIR)/, $(GENDOCFULL))

dist : src-dist full-dist lgc-dist

src-dist :  $(addprefix $(DISTDIR)/$(SRCARCHIVE),  $(ARCHIVEEXT) $(SUMEXT))

full-dist : $(addprefix $(DISTDIR)/$(FULLARCHIVE), $(ARCHIVEEXT) $(SUMEXT))

lgc-dist :  $(addprefix $(DISTDIR)/$(LGCARCHIVE),  $(ARCHIVEEXT) $(SUMEXT))

norm : $(NORMSFD)

check-harder : clean check

pre-patch : munge clean

clean :
	$(RM) -r $(TMPDIR) $(BUILDDIR) $(DISTDIR)
