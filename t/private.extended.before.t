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
                isa_ok $self, 'DBIx::Extended::db';
                return $query;
            },
        }
    );

    return (sub {$dbh}, 'SQLite', 'SQL::Abstract');
}->());

t::CRUD->run(sub {
    my $dbh = DBI->connect(
        'dbi:SQLite:dbname=:memory:', '', '', {
            RootClass => 'DBIx::Extended',
            private_extended_before_do => sub {
                my $self = shift;;
                my $query = shift;
                isa_ok $self, 'DBIx::Extended::db';
                return $query;
            },
        }
    );

    return (sub {$dbh}, 'SQLite', 'SQL::Abstract');
}->());

done_testing;

