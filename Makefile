TelegramiTunes.dylib:
	cc -o TelegramiTunes.dylib -dynamiclib TelegramiTunes.m -framework Cocoa

run: TelegramiTunes.dylib
	env DYLD_INSERT_LIBRARIES=`pwd`/TelegramiTunes.dylib /Applications/Telegram.app/Contents/MacOS/Telegram

# https://github.com/Tyilo/insert_dylib
install: TelegramiTunes.dylib
	insert_dylib --inplace TelegramiTunes.dylib /Applications/Telegram.app/Contents/MacOS/Telegram

clean:
	rm TelegramiTunes.dylib

.PHONY: clean
