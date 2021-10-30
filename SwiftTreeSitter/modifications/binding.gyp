{
  "targets": [
    {
      "target_name": "tree_sitter_go_binding",
      "include_dirs": [
        "<!(node -e \"require('nan')\")",
        "src"
      ],
      "sources": [
        "src/parser.c",
        "src/binding.cc"
      ],
      'xcode_settings': {
          'OTHER_CFLAGS': [
            "-arch x86_64"
          ],
          "OTHER_LDFLAGS":[
            "-arch x86_64",
            "-mmacosx-version-min=10.13"
          ]
      },
      "cflags_c": [
        "-std=c99",
      ]
    }
  ]
}
