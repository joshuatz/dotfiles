Utility docker images, for one-off tasks.

TODO: I should probably move this https://github.com/joshuatz/scratchpad-playgrounds

## `java_playground`

> [src](./java_playground/)

Can be used as a playground (with Temurin-based image as base), but also has auto-decompiling utils on run:

```bash
# As a playground
docker run -it --rm jtz-reg/jtz/java_playground bash

# Some decompiling examples:
# Jar(s):
docker run -it --rm \
	-v ~/jtzdev/some_file.jar:/var/some_file.jar \
	-v ~/jtzdev/decompiled/:/var/decompile_output \
	jtz-reg/jtz/java_playground

# APK(s):
docker run -it --rm \
	-v ~/jtzdev/com.my_app.apk:/var/jar_to_decompile.apk \
	-v ./decompiled:/var/decompile_output \
	jtz-reg/jtz/java_playground
```

## Pyodide Builder

> [src](./pyodide_builder/)

Image to automate the use of [pyodide-build](https://pyodide.org/en/stable/development/building-and-testing-packages.html#building-and-testing-packages-out-of-tree), to build Pyodide compatible WASM wheels from existing Python packages.

Example invocation:

```bash
docker run --rm -it \
	-e PYODIDE_BUILD_EXPORTS="whole_archive" \
	-v "/vendored/some_python_pkg_src:/var/to_compile" \
	-v "./pyodide_builder_output:/var/output" \
	jtz-reg/jtz/pyodide_builder ./autorun.sh
```
