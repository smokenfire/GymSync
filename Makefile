CHECK_ENV = dart run scripts/check_env.dart
REPLACE_FILES = dart run scripts/replace_files.dart

.PHONY: all check_env apk desktop-presence

all: check_env
	@echo "Use 'make apk' or 'make desktop-presence'"

check_env:
	$(CHECK_ENV)

apk: check_env
	cd apps/mobile_app && \
	flutter pub get && \
	flutter create . && \
	cd ../../ && \
	$(REPLACE_FILES) && \
	cd apps/mobile_app && \
	flutter build apk --release

desktop-presence: check_env
	cd apps/presence && \
	npm install && \
	npm run build