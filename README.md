# settl_range_tree_builder
Program and module to build a tree of ranges from an sequence of labeled values. Primarily intended for the development of SetTL

See `range_tree_builder.md` for documentation

The unique ids like `df825834-21e9-5494-beb2-2ee7dbcabdae` in `range_tree_builder.md` can be searched to find corresponding relevant information, uses, etc in all files

Run unit tests with:
`dmd -lowmem -g -debug -unittest -main range_tree_builder.d lib.d tree.d progressive_partition.d && ./range_tree_builder`
