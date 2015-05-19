SHELL=/bin/bash
PROJ_NAME = $(shell basename `pwd`)
CONFIG_DIR = configs
VERSION = $(shell git describe --tags)
BRANCH := $(shell git rev-parse --abbrev-ref HEAD 2>&1)

ifdef TRAVIS_TAG
ZIP_CORE := TestFlightCore-$(TRAVIS_TAG).zip
ZIP_RO := TestFlightConfigRO-$(TRAVIS_TAG).zip
ZIP_STOCK := TestFlightConfigStock-$(TRAVIS_TAG).zip
else
ZIP_CORE := TestFlightCore-$(TRAVIS_BRANCH)_$(TRAVIS_BUILD_NUMBER).zip
ZIP_RO := TestFlightConfigRO-$(TRAVIS_BRANCH)_$(TRAVIS_BUILD_NUMBER).zip
ZIP_STOCK := TestFlightConfigStock-$(TRAVIS_BRANCH)_$(TRAVIS_BUILD_NUMBER).zip
endif

all: clean meta configs
	cp -r GameData/TestFlight/ ~/Dropbox/KSP/TestFlight/

install: clean
	-rm ~/Developer/KSP/1.0/TestFlightDEV/Dev/GameData/TestFlight/Config/*.cfg
	cd $(CONFIG_DIR);python compileYamlConfigs.py Stock
	cp $(CONFIG_DIR)/Stock/*.cfg GameData/TestFlight/Config
	cp -r GameData/TestFlight/ ~/Dropbox/KSP/TestFlight/
	cp -r GameData/TestFlight/ ~/Developer/KSP/1.0/TestFlightDEV/Dev/GameData/TestFlight/

release: zip

configs: $(CONFIG_DIR)/RealismOverhaul/%.cfg $(CONFIG_DIR)/Stock/%.cfg
	cp $(CONFIG_DIR)/RealismOverhaul/*.cfg GameData/TestFlight/Config
	zip $(ZIP_RO) GameData/TestFlight/Config/*
	rm GameData/TestFlight/Config/*.cfg
	cp $(CONFIG_DIR)/Stock/*.cfg GameData/TestFlight/Config
	zip $(ZIP_STOCK) GameData/TestFlight/Config/*

$(CONFIG_DIR)/RealismOverhaul/%.cfg:
	cd $(CONFIG_DIR);python compileYamlConfigs.py RealismOverhaul

$(CONFIG_DIR)/Stock/%.cfg:
	cd $(CONFIG_DIR);python compileYamlConfigs.py Stock

ifdef TRAVIS_TAG
meta:
	python makeMeta.py $(TRAVIS_TAG)
	cp TestFlight.version GameData/TestFlight/TestFlight.version
	cp TestFlight.version GameData/TestFlight/Config/TestFlight.version
else
meta:
endif

zip: meta configs
	zip $(ZIP_CORE) GameData GameData/TestFlight/* GameData/TestFlight/Plugins/* GameData/TestFlight/Resources/* GameData/TestFlight/Resources/Textures/*

clean:
	-rm $(CONFIG_DIR)/RealismOverhaul/*.cfg
	-rm $(CONFIG_DIR)/Stock/*.cfg
	-rm GameData/TestFlight/Config/*.cfg
	-rm *.zip
	-rm GameData/TestFlight/*.version
	-rm GameData/TestFlight/Config/*.version
	-rm GameData/TestFlight/*.ckan
	-rm *.version
	-rm *.ckan

ifdef TRAVIS_TAG
deploy:
else
ifeq ($(TRAVIS_SECURE_ENV_VARS),true)
deploy:
	curl --ftp-create-dirs -T ${ZIP_CORE} -u ${FTP_USER}:${FTP_PASSWD} ftp://stantonspacebarn.com/webapps/johnvanderbeck/modding/KSP/TestFlight/$(TRAVIS_BRANCH)_$(TRAVIS_BUILD_NUMBER)/$(ZIP_CORE)
else
deploy:
	echo No secure environment available. Skipping deploy.
endif
endif
