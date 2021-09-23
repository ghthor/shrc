package main

import (
	"bytes"
	"io"
	"log"
	"os"
)

const trimSuffix = "parameter"

func main() {
	var mem bytes.Buffer
	_, err := io.Copy(&mem, os.Stdin)
	if err != nil {
		log.Fatal(err)
	}

	fixed := bytes.TrimSuffix(mem.Bytes(), []byte(trimSuffix))
	io.Copy(os.Stdout, bytes.NewReader(fixed))
}
