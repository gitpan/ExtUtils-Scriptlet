use strictures;

package ExtUtils::Scriptlet;

our $VERSION = '1.131990'; # VERSION

# ABSTRACT: run perl code in a new process without quoting it, on any OS

#
# This file is part of ExtUtils-Scriptlet
#
#
# Christian Walde has dedicated the work to the Commons by waiving all of his
# or her rights to the work worldwide under copyright law and all related or
# neighboring legal rights he or she had in the work, to the extent allowable by
# law.
#
# Works under CC0 do not require attribution. When citing the work, you should
# not imply endorsement by the author.
#

use Exporter 'import';
use autodie;
use Data::Dumper;

our @EXPORT_OK = qw( perl );


sub perl {
    my ( $code, %p ) = @_;

    die "No code given" if !$code;

    # Serialize code to protect from newline mangling. This is necessary since
    # the perl interpreter runs source code through a newline filter, no matter
    # how the file handles are configured. For the payload this is unnecessary
    # as no further filters are forced onto it.
    # Using Data::Dumper here because on 5.10.0 B::perlstring breaks with utf8
    # strings. if DD turns out to have more problems, this can be replaced with
    # B::perlstring.
    $code = Data::Dumper->new( [$code] )->Useqq( 1 )->Dump;

    $p{perl} ||= $^X;
    $p{encoding} ||= ":encoding(UTF-8)";
    $p{$_} ||= "" for qw( args argv payload );

    open                                 #
      my $fh,                            #
      "|- :raw $p{encoding}",            # :raw protects the payload from write
                                         # mangling (newlines)
      "$p{perl} $p{args} - $p{argv}";    #

    print $fh                            #
      "binmode STDIN;"                   # protect the payload from read
                                         # mangling (newlines, system locale)
      . "$code; eval \$VAR1;"            # unpack and execute serialized code
      . "die \$@ if \$@;"                #
      . "\n__END__\n"                    #
      . $p{payload};                     #

    eval {

        # prevent the host perl from being terminated if the child perl dies
        local $SIG{PIPE} = 'IGNORE';
        close $fh;                       # grab exit value so we can return it
    };

    return $?;
}

1;

__END__
=pod

=head1 NAME

ExtUtils::Scriptlet - run perl code in a new process without quoting it, on any OS

=head1 VERSION

version 1.131990

=head1 FUNCTIONS

=head2 perl

Executes a given piece of perl code in a new process while dodging shell
quoting.

=for :stopwords cpan testmatrix url annocpan anno bugtracker rt cpants kwalitee diff irc mailto metadata placeholders metacpan

=head1 SUPPORT

=head2 Bugs / Feature Requests

Please report any bugs or feature requests through the issue tracker
at L<http://rt.cpan.org/Public/Dist/Display.html?Name=ExtUtils-Scriptlet>.
You will be notified automatically of any progress on your issue.

=head2 Source Code

This is open source software.  The code repository is available for
public review and contribution under the terms of the license.

L<https://github.com/wchristian/ExtUtils-Scriptlet>

  git clone https://github.com/wchristian/ExtUtils-Scriptlet.git

=head1 AUTHOR

Christian Walde <walde.christian@googlemail.com>

=head1 COPYRIGHT AND LICENSE


Christian Walde has dedicated the work to the Commons by waiving all of his
or her rights to the work worldwide under copyright law and all related or
neighboring legal rights he or she had in the work, to the extent allowable by
law.

Works under CC0 do not require attribution. When citing the work, you should
not imply endorsement by the author.

=cut

