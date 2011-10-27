use sane;
use Test::More;
use DBI;
use t::CRUD;

t::CRUD->run(sub {
    my $dbh = DBI->connect(
        'dbi:SQLite:dbname=:memory:', '', '', {
            RootClass => 'DBIx::Extended',
            private_extended_before_prepare => sub {
                my $self = shift;;
                my $query = shift;

                my $trace;
                my $i = 0;
                while ( my @caller = caller($i) ) {
                    my $file = $caller[1];
                    $file =~ s!\*/!*\//!g;
                    $trace = "/* $file line $caller[2] */";
                    last if $caller[0] ne ref($self) && $caller[0] !~ /^(:?DBIx?|DBD)\b/;
                    $i++;
                }
                $query =~ s! ! $trace !;
                use Data::Dumper; warn Dumper {args => \@_, query => $query};
                return $query;
            },
        }
    );

    return (sub {$dbh}, 'SQLite', 'SQL::Abstract');
}->());

done_testing;

