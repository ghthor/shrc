package main

import (
	"encoding/json"
	"flag"
	"fmt"
	"log"
	"os"
)

func mustNot(err error) {
	if err != nil {
		log.Println(err)
		os.Exit(1)
	}
}

type FlakeLock struct {
	Nodes   map[string]any `json:"nodes"`
	Root    string         `json:"root"`
	Version int            `json:"version"`
}

func main() {
	var (
		from = flag.String("from", "", "flake.lock file to sync nixpkgs from")
		to   = flag.String("to", "", "flake.lock file to sync nixpkgs to")
	)
	flag.Parse()

	cwd, err := os.Getwd()
	mustNot(err)
	log.Println(cwd)

	if from == to || *to == "" || *from == "" {
		mustNot(fmt.Errorf("invalid sync targets: from(%q) == to(%q)", *from, *to))
	}

	fromBytes, err := os.ReadFile(*from)
	mustNot(err)
	toBytes, err := os.ReadFile(*to)
	mustNot(err)

	var (
		fromJson FlakeLock
		toJson   FlakeLock
	)
	mustNot(json.Unmarshal(fromBytes, &fromJson))
	mustNot(json.Unmarshal(toBytes, &toJson))

	obj := fromJson.Nodes["root"].(map[string]any)
	obj = obj["inputs"].(map[string]any)
	key := obj["nixpkgs"].(string)

	var ok bool
	if toJson.Nodes["nixpkgs"], ok = fromJson.Nodes[key]; !ok {
		mustNot(fmt.Errorf("%s missing nixpkgs key", *from))
	}

	out, err := os.OpenFile(*to, os.O_WRONLY|os.O_TRUNC|os.O_CREATE, 0644)
	mustNot(err)
	defer out.Close()

	enc := json.NewEncoder(out)
	enc.SetIndent("", "  ")
	mustNot(enc.Encode(toJson))
}
