package t::CRUD;
use sane;
use Test::More;

sub run {
    my ($class, $get_dbh, $driver, $builder) = @_;

    my $dbh = $get_dbh->();
    isa_ok $dbh, 'DBI::db';

    { eval { $dbh->do("DROP TABLE sake") } }

    { # query without @bind
        my $sql = $driver eq 'mysql'
            ? "CREATE TABLE sake (id INT AUTO_INCREMENT PRIMARY KEY, name TEXT)"
            : $driver eq 'SQLite'
                ? "CREATE TABLE sake (id INTEGER PRIMARY KEY, name TEXT)"
                : die "Unsupported driver";

        ok $dbh->query($sql);
    }

    my @kubota = qw/生原酒 萬寿 翠寿 碧寿 紅寿 千寿 百寿/;
    my $order_by_id_asc = [];

    for my $id (0 .. $#kubota) {
        push @$order_by_id_asc, +{
            id   => ($id + 1),
            name => $kubota[$id],
        };
    }

    { # builder
        isa_ok $dbh->builder, $builder;
    }

    { # insert
        for my $name (@kubota) {
            ok $dbh->insert(sake => { name => $name });
        }
    }

    { # last_insert_id
        is $dbh->last_insert_id, scalar @kubota;
    }

    { # select
        is_deeply $dbh->select('sake', ['*'], {id => 1}), $order_by_id_asc->[0];
    }

    { # selectall
        is_deeply $dbh->selectall('sake', ['*'], {}, {-asc => 'id'}), $order_by_id_asc;
    }

    { # update
        ok $dbh->update(sake => {
            name => '越州 雪げしき'
        }, {
            id => 1
        });
        $order_by_id_asc->[0]{name} = '越州 雪げしき';

        is_deeply $dbh->select('sake', ['*'], {id => 1}), $order_by_id_asc->[0];
    }

    { # delete
        ok $dbh->delete(sake => {id => 1});
        shift @$order_by_id_asc;
        is_deeply $dbh->selectall('sake', ['*']), $order_by_id_asc;
    }

    { # query
        ok $dbh->query('DELETE FROM sake WHERE id > ?', 2);
        is_deeply $dbh->selectall('sake', ['*']), [$order_by_id_asc->[0]];
    }

    { # RaiseError and ShowErrorStatement
        local $@;
        eval { $dbh->query("FOO") };
        like $@, qr/(DBD::SQLite::db prepare failed|DBD::mysql::st execute failed)/;
    }

    $dbh->disconnect;
}

1;
__END__
