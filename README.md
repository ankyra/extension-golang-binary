# Golang extension for Escape

This Escape extension can be used to build and test Go binaries. No local
toolchain is required as this build uses the public Go Docker image to perform
builds.

Please see https://escape.ankyra.io/docs/ for the full documentation on Escape.

## Usage

### Building a binary

```yaml
name: my-project/my-go-build
version: '0.1.@'

extends:
- extension-golang-binary-latest

inputs:
- id: package_name
  default: github.com/my-project/my-go-build
- id: binary_name
  default: my-go-build
```

### Vendoring Escape dependencies

```yaml
name: my-project/my-go-build
version: '0.1.@'

extends:
- extension-golang-binary-latest

depends:
- escape-core-latest as core

inputs:
- id: package_name
  default: github.com/my-project/my-go-build
- id: binary_name
  default: my-go-build
- id: escape_go_dependencies
  type: list[string]
  default: 
  - _/escape-core:github.com/ankyra/escape-core
```

### Overriding build and test commands

```yaml
name: my-project/my-go-build
version: '0.1.@'

extends:
- extension-golang-binary-latest

inputs:
- id: package_name
  default: github.com/my-project/my-go-build
- id: binary_name
  default: my-go-build
- id: build_command
  default: go build -v
- id: build_command
  default: go test -v
```

## License

```
Copyright 2017 Ankyra

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
```
