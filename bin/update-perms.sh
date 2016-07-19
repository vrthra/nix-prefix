find ../nix -perm 600 | while read a ; do chmod 660 $a; done
find ../nix -perm 644 | while read a ; do chmod 664 $a; done
find ../nix -perm 755 | while read a ; do chmod 775 $a; done
