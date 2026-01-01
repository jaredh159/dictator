_default:
  @just --choose

build:
  @xcodebuild -project Dictator.xcodeproj -scheme Dictator -configuration Debug build 2>&1 | grep -E "(error:|warning:|BUILD)"

run: build
  @open "$HOME/Library/Developer/Xcode/DerivedData/Dictator-"*/Build/Products/Debug/Dictator.app

kill:
  @pkill -x Dictator || true

restart: kill run

logs:
  @log stream --predicate 'subsystem == "com.jaredh159.dictator"' --level info

clean:
  @xcodebuild -project Dictator.xcodeproj -scheme Dictator clean 2>&1 | tail -1
  @rm -rf ~/Library/Developer/Xcode/DerivedData/Dictator-*
