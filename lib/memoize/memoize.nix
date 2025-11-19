{ lib, ... }:
let
  keys =
    let
      nonNullBytesStr =
        builtins.readFile ./bytes.dat;
      nonNullItems =
        lib.stringToCharacters nonNullBytesStr;

      keysList = [ "" ] ++ nonNullItems;

      byteNames = lib.genAttrs keysList (k: null);
    in
    byteNames;

  /**
    Produce an infinite trie for memoizing a function with a string input.
    
    This uses memory in terms of a large factor of the number of unique string suffixes passed to the memoizeStr / queryTrie functions.
  */
  makeTrie = prefix: f:
    lib.mapAttrs
      (k: v: if k == "" then f prefix else makeTrie (prefix + k) f)
      keys;

  queryTrie =
    trie: needle:
    let
      needleList = lib.stringToCharacters needle;
      destination = lib.foldl'
        (subtrie: c: subtrie.${c})
        trie
        needleList;
    in
    destination."";

in
{
  /**
    Turn a function that accepts a string input into one that memoizes the results.
    Make sure to partially apply it and use it over and over in e.g. the same let binding.
    Otherwise, you're wasting kilobytes of memory allocations *for each letter in each call*.
    That's 12+ KB per input byte on Nix 2.31, and more on older versions.
    Yes, this function is surprisingly EXPENSIVE, but cheaper than e.g. reinvoking Nixpkgs.
    Its memory cost is comparable to that of loading a small Nix file.
   */
  memoizeStr = f:
    let trie = makeTrie "" f;
    in queryTrie trie;
}
