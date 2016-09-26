BEGIN { chdir 't' if -d 't' }

use Test::More;
use strict;
use lib '../lib';

use File::Spec ();
use File::Temp qw( tempfile );
use Data::Dump qw( pp );

use Archive::Tar;

# tarballs available for testing
my @archives = (
    #  [qw( src short bar.tar )],
  [qw( src long bar.tar )],
  #  [qw( src linktest linktest_with_dir.tar )],
);
#push @archives,
#  [qw( src short foo.tgz )],
#  [qw( src long foo.tgz )]
#  if Archive::Tar->has_zlib_support;
#push @archives,
#  [qw( src short foo.tbz )],
#  [qw( src long foo.tbz )]
#  if Archive::Tar->has_bzip2_support;

@archives = map File::Spec->catfile(@$_), @archives;

plan tests => scalar @archives;

# roundtrip test
for my $archive (@archives) {

      # create a new tarball with the same content as the old one
      my $old = Archive::Tar->new($archive);
say STDERR "OLD";
#pp([ $old->get_files ]);
      my $new = Archive::Tar->new();
      $new->add_files( $old->get_files );
say STDERR "NEW";
pp([ $new->get_files ]);
# So far, so good. 3rd and 4th entries -- the two directory entries -- have
# trailing slashes.

      # save differently if compressed
      my $ext = ( split /\./, $archive )[-1];
      my @compress =
          $ext =~ /t?gz$/       ? (COMPRESS_GZIP)
        : $ext =~ /(tbz|bz2?)$/ ? (COMPRESS_BZIP)
        : ();
say STDERR "\@compress";
#pp(\@compress);
      my ( $fh, $filename ) = tempfile( UNLINK => 1 );
      $new->write( $filename, @compress );
say STDERR "CCC: $filename";
my @output = qx{tar tvf $filename};
# It is already at this point that the trailing slashes have disappeared from
# the 3rd and 4th entries -- the two entries that are directories.
pp([ @output ]);

      # read the archive again from disk
      $new = Archive::Tar->new($filename);

      TODO: {
        local $TODO = 'Need to work out why no trailing slash';

      # compare list of files
      is_deeply(
          [ $new->list_files ],
          [ $old->list_files ],
          "$archive roundtrip on file names"
      ) or pp(
          [ $new->list_files ],
          [ $old->list_files ],
      );
      };
}
