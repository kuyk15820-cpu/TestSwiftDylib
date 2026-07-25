ARCHS := arm64

TARGET := iphone:clang:latest:12.2

include $(THEOS)/makefiles/common.mk

XCODEPROJ_NAME = ClearFilzaResidue

include $(THEOS_MAKE_PATH)/xcodeproj.mk

before-package::
	@if [ -f $(THEOS_STAGING_DIR)/Applications/$(XCODEPROJ_NAME).app/Info.plist ]; then \
		echo -e "\033[32mSigning with ldid...\033[0m"; \
		ldid -Sentitlements.plist $(THEOS_STAGING_DIR)/Applications/$(XCODEPROJ_NAME).app; \
	else \
		echo -e "\033[31mNo Info.plist found. Skipping ldid signing.\033[0m"; \
	fi
	@echo -e "\033[32mRemoving _CodeSignature folder...\033[0m"
	@rm -rf $(THEOS_STAGING_DIR)/Applications/$(XCODEPROJ_NAME).app/_CodeSignature

after-package::
	@echo -e "\033[32mRenaming .ipa to .tipa...\033[0m"
	@for file in ./packages/*.ipa; do \
		[ -e "$$file" ] || continue; \
		mv "$$file" "$${file%.ipa}.tipa"; \
	done
	@echo -e "\033[1;32m\n** Build Succeeded **\n\033[0m"
