package lua

import (
	"syscall"

	"github.com/zetamatta/go-ansicfile"
)

type stream_t struct {
	FilePtr ansicfile.FilePtr
	Closer  uintptr
}

func (this Lua) pushStream(fd ansicfile.FilePtr, closer func(Lua) int) {
	this.PushUserData(&stream_t{
		FilePtr: fd,
		Closer:  syscall.NewCallbackCDecl(closer),
	})
	this.GetField(LUA_REGISTRYINDEX, LUA_FILEHANDLE) // metatable
	this.SetMetaTable(-2)
}

func closer(this Lua) int {
	userdata := stream_t{}
	this.ToUserDataTo(1, &userdata)
	userdata.FilePtr.Close()
	// print("stream_closed\n")
	return 0
}

func (this Lua) PushStream(filePtr ansicfile.FilePtr) {
	this.pushStream(filePtr, closer)
}

func noncloser(this Lua) int {
	return 0
}

func (this Lua) PushStreamDontClose(filePtr ansicfile.FilePtr) {
	this.pushStream(filePtr, noncloser)
}
