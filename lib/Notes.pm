package Notes;
use Dancer2;

use Cwd;

our $VERSION = '0.1';

get '/' => sub {
    session( 'user' ) or redirect( '/recognize' );

    template index => {};

};

get '/recognize' => sub {
    session user => undef;
   
    template recognize => {};

};

get '/test' => sub {

    my $test = config->{ 'notes' };
    
    open my $fh, ">", $test;
    close $fh;

    my $pwd = getcwd();
    return "$pwd";
};

true;
