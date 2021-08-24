package main

import (
	"bytes"
	"fmt"
	"io"
	"log"
	"os"
)

const trimSuffix = "parameter"

func main() {
	fmt.Println("vim-go")

	var mem bytes.Buffer
	_, err := io.Copy(&mem, os.Stdin)
	if err != nil {
		log.Fatal(err)
	}

	fixed := bytes.TrimSuffix(mem.Bytes(), []byte(trimSuffix))
	io.Copy(os.Stdout, bytes.NewReader(fixed))
}
