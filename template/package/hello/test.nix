{ hello, runCommand }:

runCommand "test-hello"
{
  inherit hello;
} '' 
  (
    set -x
    [[ "Hello world" == "$(${hello}/bin/hello)" ]]
  )
  touch $out
''
