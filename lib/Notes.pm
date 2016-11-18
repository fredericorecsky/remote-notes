package Notes;
use Dancer2;

use Cwd;

use Authen::OATH;
use Convert::Base32 qw( decode_base32 );
use Digest::MD5 qw/md5_hex/;
use File::Finder;

our $VERSION = '0.1';

my $directory = config->{ notes };

die "$directory must end on /\n" if $directory =~ /\/$/;

if (! -d $directory . "/.notes/" ) {
    mkdir $directory . "/.notes/";
}

get '/' => sub {
    session( 'user' ) or redirect( '/recognize' );

    my @files = grep { !/\.notes/ }
                map { substr( $_, ( length $directory ) ) } 
                File::Finder->in( $directory );

    template index => { 
        title   => "Files",
        files   => \@files,
    };
};

get '/recognize' => sub {
    session user => undef;
   
    template recognize => { 
        message => session('last_message') 
    };

};

post '/recognize' => sub {
    my $secret = config->{ 'secret' };

    my $oath = Authen::OATH->new;
    my $otp  = $oath->totp( decode_base32( $secret ) );


    my $user_login = params->{ input };

    if ( $otp eq $user_login ) {
        session user => 1;
        redirect( '/' );
    } else {
        session last_message => "Failed";
        redirect( '/recognize' );
    }

};

get '/:file' => sub {
    session( 'user' ) or redirect( '/recognize' );

    my $filename  = $directory . "/" . params->{ file };

    my $content;
    if ( -e $filename ) {
        open my $fh, "<", $filename or die;
        local $/;
        $content = <$fh>;
        close $fh;
    } else {
        # create new
    }

    template editor => { 
        title   => params->{ file }, 
        action  => params->{ file },
        content => $content,
    };

};

post '/:file' => sub {
    session( 'user' ) or redirect( '/recognize' );


    my $timestamp = time();
    my $content = params->{ content };
    my $md5_sum = md5_hex $content;

    my $backup_file = $directory . "/.notes/" . "$md5_sum\_$timestamp\_". params->{ file };
    my $file = "$directory/" . params->{ file };

    for my $versions ( $file, $backup_file ) {
        open my $fh, ">", $versions
            or die "$! : $versions";
            print $fh $content;
        close $fh;
        
        open my $fh_chk, "<", $versions
            or die "$! : $versions";
            local $/;
            my $written = <$fh_chk>;
        close $fh_chk;

        if ( $md5_sum ne md5_hex $written ) {
            return '<div id="boom">0</div>';
        }
    }
    
    return '<div id="boom">1</div>';
};

true;

