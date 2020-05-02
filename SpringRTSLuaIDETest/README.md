#  SpringRTSLuaIDETest

The SpringRTS community has suffered from a lack of a major IDE since its creation. Entering into game development with the SpringRTS engine is a daunting task with few tools to simplify the process.

This project is designed to approach designing an IDE that reduces the complexity of creating a game with the SpringRTS engine, making RTS game development with the engine more approachable for new developers.



## Why a new IDE, not a plugin for existing IDEs?

MasterBel2 has a sever case of NIH. He also is interested in learning the principles behind how existing IDEs work, and so although he fully understands the limitations that come with reinventing the wheel, at this point in time he sees the learning opportunity one too good to be missed.

Also, he really needed an excuse to learn the mechanics behind XCode's "Document-based application" option.

**People urgently wanting a SpringRTS IDE should first consider extending an already exsiting LuaIDE.** This project is by no means the most efficient means to that end. 

## Current functionality & direction

The IDE, at this point in time, is simply a Lua file editor and syntax highlighter. Various QOL features, such as error detection, autocomplete, and instant documentation are either in progress or somewhat fully implemented.

## Yes, I still want to contribute

1. Send a private message to MasterBel on the SpringRTS forums to get in contact (or message him at MasterBel2#0572 on Discord). This code isn't yet lisenced as GPL/etc, so that will come as high priority in such a scenario. 
2. Read `Document.update(_:)` in Document.swift to see an overview of the current structure of the program. Direct further questions to MasterBel2.

As most code is experimental, it is also undocumented. Documentation is constantly being added, especially to less-comprehensible portions of the code. Don't be afraid to ask – MasterBel2 will answer and promptly update documentation with the aim of preventing further confusion. `Parser.swift` is currently the best-documented file.
