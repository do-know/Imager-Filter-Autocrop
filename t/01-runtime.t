#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More 'no_plan';
use MIME::Base64;
use Imager;
use Imager::Filter::Autocrop 'autocrop_test';

my $img = Imager->new();
my %types = $img->can('read_types') ? map {$_, 1} Imager->read_types : %Imager::formats;
my $images = load();

foreach my $type (keys %{$images}) {
    if ($types{$type}) {
         my $rt = 0;
         foreach my $i (@{$images->{$type}}) {
             my ($data, $expect, $opts, $desc) = @$i;
             $desc = "$type $rt"
                 unless defined $desc;
             $img->read(data => $i->[0], type => $type) or die $img->errstr;
             my %detect;
             my $got = $img->filter(type => 'autocrop_test', detect => \%detect,
                                    %$opts);
             if (ref $expect eq 'HASH') {
                 isa_ok($got, 'Imager', "$desc - no error");
                 is_deeply(\%detect, $expect, "$desc - crop correct");
             } else {
                 is($got, undef, "$desc - return undef");
                 is($img->errstr, $expect, "$desc - expected error");
             }
             ++$rt;
         }
    }
}

my $borders = Imager->new(xsize => 256, ysize => 192, channels => 3);
$borders->box(filled => 1, color => "#FFFFFF");
my %rect = (
    left => 6,
    top => 9,
    right => 42,
    bottom => 54
);
$borders->box(color => '#ff9900', filled => 1,
              xmin => $rect{left}, xmax=> $rect{right},
              ymin => $rect{top}, ymax=> $rect{bottom});

my %detect;
my $cropped = $borders->filter(type => 'autocrop_test', detect => \%detect);
isa_ok($cropped, 'Imager', "no error");

# Seems that how 'crop' and 'rect' treat coordinates is slightly inconsistent:
++$rect{bottom};
++$rect{right};
is_deeply(\%detect, \%rect, 'crop test, no border');

undef %detect;
$cropped = $borders->filter(type => 'autocrop_test', detect => \%detect,
                            border => 3);
isa_ok($cropped, 'Imager', "no error");

$rect{$_} += 3
    for qw(right bottom);
$rect{$_} -= 3
    for qw(top left);
is_deeply(\%detect, \%rect, 'crop test, border => 3');

undef %detect;
$cropped = $borders->filter(type => 'autocrop_test', detect => \%detect,
                            border => 212);
isa_ok($cropped, 'Imager', "no error");
is_deeply(\%detect, { bottom => 192, left => 0, right => 255, top => 0 },
          'crop test, border => 212');

undef %detect;
$cropped = $borders->filter(type => 'autocrop_test', detect => \%detect,
                            border => 213);
is($cropped, undef, "expect an error for border => 213");
is($borders->errstr, 'AUTOCROP_ERROR_NOCROP: Nothing to crop',
   "expected error for border => 213");
is_deeply(\%detect, {}, 'crop test, border => 213');

diag( "Testing Imager::Filter::Autocrop $Imager::Filter::Autocrop::VERSION, Perl $], $^X" );

sub load {
    my $images = {
        gif => [ 
            [ qq~R0lGODlhUAAyAOcqAAAAAAEBAQICAgMDAwQEBAUFBQYGBgcHBwgICAkJCQoKCgsLCwwMDA0NDQ4ODg8PDxAQEBERERISEhMTExQUFBUVFRYWFhcXFxgYGBkZGRoaGhsbGxwcHB0dHR4eHh8fHyAgICEhISIiIiMjIyQkJCUlJSYmJicnJygoKCkpKSoqKisrKywsLC0tLS4uLi8vLzAwMDExMTIyMjMzMzQ0NDU1NTY2Njc3Nzg4ODk5OTo6Ojs7Ozw8PD09PT4+Pj8/P0BAQEFBQUJCQkNDQ0REREVFRUZGRkdHR0hISElJSUpKSktLS0xMTE1NTU5OTk9PT1BQUFFRUVJSUlNTU1RUVFVVVVZWVldXV1hYWFlZWVpaWltbW1xcXF1dXV5eXl9fX2BgYGFhYWJiYmNjY2RkZGVlZWZmZmdnZ2hoaGlpaWpqamtra2xsbG1tbW5ubm9vb3BwcHFxcXJycnNzc3R0dHV1dXZ2dnd3d3h4eHl5eXp6ent7e3x8fH19fX5+fn9/f4CAgIGBgYKCgoODg4SEhIWFhYaGhoeHh4iIiImJiYqKiouLi4yMjI2NjY6Ojo+Pj5CQkJGRkZKSkpOTk5SUlJWVlZaWlpeXl5iYmJmZmZqampubm5ycnJ2dnZ6enp+fn6CgoKGhoaKioqOjo6SkpKWlpaampqenp6ioqKmpqaqqqqurq6ysrK2tra6urq+vr7CwsLGxsbKysrOzs7S0tLW1tba2tre3t7i4uLm5ubq6uru7u7y8vL29vb6+vr+/v8DAwMHBwcLCwsPDw8TExMXFxcbGxsfHx8jIyMnJycrKysvLy8zMzM3Nzc7Ozs/Pz9DQ0NHR0dLS0tPT09TU1NXV1dbW1tfX19jY2NnZ2dra2tvb29zc3N3d3d7e3t/f3+Dg4OHh4eLi4uPj4+Tk5OXl5ebm5ufn5+jo6Onp6erq6uvr6+zs7O3t7e7u7u/v7/Dw8PHx8fLy8vPz8/T09PX19fb29vf39/j4+Pn5+fr6+vv7+/z8/P39/f7+/v///yH5BAEKAPsALAAAAABQADIAAAj+AP8JHEiwoMGDCBMqXMiwocOHECNKnEixosWLGDNq3Mixo8ePIEOKHEmypMmTKFOqXMmypcuXMGMmfAKAiUF/RQBckRlxXAMArApSAoChHc+IkABsiDdwmwIAs45G5EcDABuB/HIAECNVorMBApT9OwTgA9OuEeUAgOHMQIBeaCXS+wDg59W4EmcBAFCiHl6JyQQAUPI3or0Te4EWfugGQItHSuUtZvgrQIFn/XAAaDNZoTy6gwRGIyBgWWeEYgDU4DfQDgAZrE8TpAUAwTWC9UAAeCR7IDsMABwZtAWAwbje/6wA8OHv4BUAT5BLn069uvXr2LNr3869u/fv4MMFix8PMyAAOw==~,
              { bottom => 32, left => 33, right => 47, top => 15} ],
            [ qq~R0lGODlhUAAyAOcqAAAAAAEBAQICAgMDAwQEBAUFBQYGBgcHBwgICAkJCQoKCgsLCwwMDA0NDQ4ODg8PDxAQEBERERISEhMTExQUFBUVFRYWFhcXFxgYGBkZGRoaGhsbGxwcHB0dHR4eHh8fHyAgICEhISIiIiMjIyQkJCUlJSYmJicnJygoKCkpKSoqKisrKywsLC0tLS4uLi8vLzAwMDExMTIyMjMzMzQ0NDU1NTY2Njc3Nzg4ODk5OTo6Ojs7Ozw8PD09PT4+Pj8/P0BAQEFBQUJCQkNDQ0REREVFRUZGRkdHR0hISElJSUpKSktLS0xMTE1NTU5OTk9PT1BQUFFRUVJSUlNTU1RUVFVVVVZWVldXV1hYWFlZWVpaWltbW1xcXF1dXV5eXl9fX2BgYGFhYWJiYmNjY2RkZGVlZWZmZmdnZ2hoaGlpaWpqamtra2xsbG1tbW5ubm9vb3BwcHFxcXJycnNzc3R0dHV1dXZ2dnd3d3h4eHl5eXp6ent7e3x8fH19fX5+fn9/f4CAgIGBgYKCgoODg4SEhIWFhYaGhoeHh4iIiImJiYqKiouLi4yMjI2NjY6Ojo+Pj5CQkJGRkZKSkpOTk5SUlJWVlZaWlpeXl5iYmJmZmZqampubm5ycnJ2dnZ6enp+fn6CgoKGhoaKioqOjo6SkpKWlpaampqenp6ioqKmpqaqqqqurq6ysrK2tra6urq+vr7CwsLGxsbKysrOzs7S0tLW1tba2tre3t7i4uLm5ubq6uru7u7y8vL29vb6+vr+/v8DAwMHBwcLCwsPDw8TExMXFxcbGxsfHx8jIyMnJycrKysvLy8zMzM3Nzc7Ozs/Pz9DQ0NHR0dLS0tPT09TU1NXV1dbW1tfX19jY2NnZ2dra2tvb29zc3N3d3d7e3t/f3+Dg4OHh4eLi4uPj4+Tk5OXl5ebm5ufn5+jo6Onp6erq6uvr6+zs7O3t7e7u7u/v7/Dw8PHx8fLy8vPz8/T09PX19fb29vf39/j4+Pn5+fr6+vv7+/z8/P39/f7+/v///yH5BAEKAP8ALAAAAABQADIAAAifAP8JHEiwoMGDCBMqXMiwocOHECNKnEixosWLGDNq3Mixo8ePIEOKHEmypMmTKFOqXMmypcuXMGPKnEmzps2bDwHoPKgTAE6GOw0G/blwqECjRBP2HLg0KVCfR6E6LboT6VSlPaVepap1q8KmXr+CDcuzaleyTKGORfvPqNWwY9fCPfv2at26SeVGPcu2r9+/gAMLHky4sOHDiBMrrhgQADs=~,
              { bottom => 36, left => 34, right => 48, top => 19} ],
            [ qq~R0lGODlhUAAyAMZEAAAAAAEBAQICAgMDAwQEBAUFBQYGBggICAoKCgwMDA0NDRgYGBsbGx8fHyAgICUlJScnJy0tLTAwMDIyMjQ0NDU1NTg4ODk5OT4+PkVFRUpKSkxMTE9PT1ZWVldXV2JiYmxsbG1tbW5ubnJycnZ2doODg4eHh46Ojo+Pj5CQkJSUlKysrLOzs7S0tLa2tr29vb+/v8nJycrKysvLy87Ozs/Pz9HR0dfX19vb2+Pj4+zs7O3t7fHx8fLy8vT09PX19fb29vz8/P39/f7+/v///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////yH5BAEKAH8ALAAAAABQADIAAAfxgESCg4SFhoeIiYqLjI2Oj5CRkpOUlZaXmJmam5ydnp+goaKjpKWmp6ipqqusra6vsLGys7S1qRwAG4ZDGQAeto05CgArhSoACzvAjSkADDyDOAgALMuNQRQAIIJBFwAf1o40AwIyRCYADdDhjSMAEjQGAS/sjj4NAMPb9Y4sAAAPfvBzFEMAAA0DGwGB8I9YwkUiAERA4azHQ0QwAhSoIcQCgBAXDfXAV0KQDQICZoQk9AFAhSCDSACYAHNlCwAHbhD64QAAipU6FgA4YcgFgAQ5QnYAgGHIIQ8AOKycSrWq1atYs2rdyrWr169gw64KBAA7~,
              { bottom => 35, left => 31, right => 45, top => 18} ],
            [ qq~R0lGODlhUAAyAIABAAAAAP///yH5BAEKAAEALAAAAABQADIAAAJxjI+py+0Po5y02ouz3rz7D4biSJbmiabqyrbuC8fyTNf2jef6HgH+4gPwID9Fcfg4GpTIRvDwbBKFS6o0+WNenUHrFuv9OqLiMbkMzIbRUOqZHVBqy+c3fT3f5vNNe3UNFyg4SFhoeIiYqLjI2Oi4UQAAOw==~,
              { bottom => 36, left => 32, right => 46, top => 19} ],
        ],
        jpeg => [
            [ qq~/9j/4AAQSkZJRgABAQEASABIAAD/2wBDAAMCAgMCAgMDAwMEAwMEBQgFBQQEBQoHBwYIDAoMDAsKCwsNDhIQDQ4RDgsLEBYQERMUFRUVDA8XGBYUGBIUFRT/wgALCAAyAFABAREA/8QAFwABAQEBAAAAAAAAAAAAAAAAAAcECP/aAAgBAQAAAAHqkABibQEozWABG1kAAAAAH//EABwQAAEEAwEAAAAAAAAAAAAAAAQCAwUGASYwUP/aAAgBAQABBQLsk0dZT5o4znC7BOg5qbS7LI8JtebjOxOm2Twv/8QAKxAAAgEBBAcJAAAAAAAAAAAAAQMCBAAFEUIGEhUwQVHRIiQzQ1BTYXHB/9oACAEBAAY/At9Omi9cqmA1pJExrgc8LKW561McdVcZzAMz8c9yjSKiHe7v8WPvIzR/bT0mq44QliqgSfLXxl9nc7DSTs2kIZeDI5zlV1tK6Zdm6rwJbRHgtmZfT0P/xAAgEAEAAQIHAQEAAAAAAAAAAAABESFxADAxQWGB0VBR/9oACAEBAAE/Ic4ksVBWinIVK44HOXIK1WyQaQNeBNS1R3vGFkGqeNReeep2jJKzU5SWRbk2fpjeoQ8SOvpfh//aAAgBAQAAABD/AP8A/wC//wD/AP8A/wD/AP/EABwQAQEBAAIDAQAAAAAAAAAAAAERITAxAEFQUf/aAAgBAQABPxDmjakkNCqYIBp++LsgEPKUdDAunDZ3qNhX9UqXpoHwVqHogWigQqaQqo4BlmiAIB7cBz2Iuj9P7v3coC60C/DH/9k=~,
              { bottom => 32, left => 32, right => 48, top => 8} ],
            [ qq~/9j/4AAQSkZJRgABAQEASABIAAD/2wBDAAMCAgMCAgMDAwMEAwMEBQgFBQQEBQoHBwYIDAoMDAsKCwsNDhIQDQ4RDgsLEBYQERMUFRUVDA8XGBYUGBIUFRT/wgALCAAyAFABAREA/8QAGQABAQEAAwAAAAAAAAAAAAAAAAYHAQII/9oACAEBAAAAAfVIAAAIHpoICKzbfgEZzZAAAA//xAAdEAACAQQDAAAAAAAAAAAAAAAEBgUDFTBAAQIH/9oACAEBAAEFAthlniV0mXYa/WZwOR4gC75nQ5hicBa5cGGcXbqZsf/EACcQAAEDAgQFBQAAAAAAAAAAAAECAwQFEhETITEAIzBAQRQyUVJi/9oACAEBAAY/Au4gyFobVSFrypK8De0T7Vb7cQqTTEtPS3ea8twEpZZ+dDufHRlma3ntupykseXVHZI4nUyoNlus2odvWq7MawAAB/O3RjVGTIzWIqeRFs0Sv7k46niBNYkejnQ14pesuuT5QRiND3P/xAAhEAABAwMEAwAAAAAAAAAAAAABESExAFFhMEBBsXGB0f/aAAgBAQABPyHcWQqjIqx8t3TXskMkwDAXsaKuCBLXmK6iEXij6wWoYZEg+aLixRj59AMEaoFhyJb0eRnvuf/aAAgBAQAAABD/AP8A/wB/z/f/AP8A/wD/xAAbEAEBAQEAAwEAAAAAAAAAAAABESExMEBBAP/aAAgBAQABPxD2DcxXTcHrAWyEVATLbmnFiohALLieH4bXODBFvgKEPxWyDRWV1RAoLBTHg4fy8xrqQQSlGivyIHI0IQGXVR17P//Z~,
              { bottom => 40, left => 32, right => 48, top => 16} ],
            [ qq~/9j/4AAQSkZJRgABAQEASABIAAD/2wBDAAMCAgMCAgMDAwMEAwMEBQgFBQQEBQoHBwYIDAoMDAsKCwsNDhIQDQ4RDgsLEBYQERMUFRUVDA8XGBYUGBIUFRT/2wBDAQMEBAUEBQkFBQkUDQsNFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBT/wgARCAAyAFADAREAAhEBAxEB/8QAGgABAAIDAQAAAAAAAAAAAAAAAAUHAgYIA//EABQBAQAAAAAAAAAAAAAAAAAAAAD/2gAMAwEAAhADEAAAAeqQAAAAAAAAAAAVUSJYgAAAOdi3zagAADzIAxNlAAAAAAAAAAAB/8QAHBABAAMAAgMAAAAAAAAAAAAABQMEBgJAEiAw/9oACAEBAAEFAuwfoZyWsmgg58d1Wl2yWYZhdF95OPnwCBrZ6lQArmJ9j//EABQRAQAAAAAAAAAAAAAAAAAAAGD/2gAIAQMBAT8BDf/EABQRAQAAAAAAAAAAAAAAAAAAAGD/2gAIAQIBAT8BDf/EACYQAAICAAUDBAMAAAAAAAAAAAECAwQABRESMSFBUhMUMEBTcfD/2gAIAQEABj8C+xmGWZ1ZBCqbVW0yhd8XcdO64s5nYYxUJzpTqlRqE8yeevwnLMuijkOWKZpp28yOkQ/f9xivZhT0umx4fxMOV+BlDFCRpuXkY9tW3vucyPLKdXkY9ycXbtd5ENwhpIdR6e7yA05+z//EACAQAAIBAwUBAQAAAAAAAAAAAAERIQAxQTBAUWFxgZH/2gAIAQEAAT8h3AETIsIZ0AgOGZNRStTB4Ur01+jRHGZFi43KT5QeJU4VmnCx0tApR0CvUMEP0UYkQUnTIwDPzFWjEDHuAWZnc//aAAwDAQACAAMAAAAQkkkkkkkkkkkkkkkkkAkkkkgkkkkkkkkkkkk//8QAFBEBAAAAAAAAAAAAAAAAAAAAYP/aAAgBAwEBPxAN/8QAFBEBAAAAAAAAAAAAAAAAAAAAYP/aAAgBAgEBPxAN/8QAGxABAQEAAgMAAAAAAAAAAAAAAREhADAxQEH/2gAIAQEAAT8Q9hk2Tigb+xICUCkVqlRhs2IchUEQ6FeVKVgKn1bgioofJE+MQ7MMwhpwvQHoIEiIZw8lCmiZwtNAIEoPhQYOX8Sekj9D7ylUoJ7H/9k=~,
              { bottom => 40, left => 24, right => 48, top => 16} ],
            [ qq~/9j/4AAQSkZJRgABAQEASABIAAD/2wBDAAMCAgMCAgMDAwMEAwMEBQgFBQQEBQoHBwYIDAoMDAsKCwsNDhIQDQ4RDgsLEBYQERMUFRUVDA8XGBYUGBIUFRT/2wBDAQMEBAUEBQkFBQkUDQsNFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBQUFBT/wgARCAAyAFADAREAAhEBAxEB/8QAGAABAQEBAQAAAAAAAAAAAAAAAAYHAQj/xAAUAQEAAAAAAAAAAAAAAAAAAAAA/9oADAMBAAIQAxAAAAH1SAAAAAAAAAAACAOGgAAAAxIpjRwAAARh0sgAAAAAAAAAAAf/xAAeEAACAQQDAQAAAAAAAAAAAAAEBQYDBzBAARQVJf/aAAgBAQABBQLYpPyBpUqkBDt/guR9Pi35AtWMYEsc81gPHelI9j//xAAUEQEAAAAAAAAAAAAAAAAAAABg/9oACAEDAQE/AQ3/xAAUEQEAAAAAAAAAAAAAAAAAAABg/9oACAECAQE/AQ3/xAAnEAAABAQEBwEAAAAAAAAAAAABAgMEBRESIQATMTIUFSMwQEFRsf/aAAgBAQAGPwLyFIS/ImRNcmYxWIAhXLcUb7gw7SaET5S06Z3AgNSivwt9A7LCEsiZkZUUzkDFNSKABqcR9fMNkmyXDmb9FdEdxFQ3T/ey+iDhxxj52a6tFNBPRACY2wvE2zjKSckk4bUWOYNDznYfJ//EACAQAAIBAwUBAQAAAAAAAAAAAAEhQQARUTAxQHGhkdH/2gAIAQEAAT8h5CyVJGTLIrKGKIIvklnTIbH3RG+oCDDDYfrsCnTH+mAT60ZqsLIcUB21ikOG624gEUbvPJ//2gAMAwEAAgADAAAAEJJJJJJJJJJJJBJJJJIJJJJBJJJJJJJJJJJJP//EABQRAQAAAAAAAAAAAAAAAAAAAGD/2gAIAQMBAT8QDf/EABQRAQAAAAAAAAAAAAAAAAAAAGD/2gAIAQIBAT8QDf/EAB4QAQEBAAEEAwAAAAAAAAAAAAERITEAMEBBUWFx/9oACAEBAAE/EPInI4VM4a/QEWIdB8h5ykkE0tRkwp2ERvq2fMhCDK0olS/v4H91bT6PEh2MOV4VtZINdMTtdfM5f5ShJQkFMaPI/9k=~,
              { bottom => 40, left => 32, right => 48, top => 16} ],
        ],
        png => [
            [ qq~iVBORw0KGgoAAAANSUhEUgAAAEAAAAAqCAIAAACMZMq1AAAAH0lEQVRYhe3BMQEAAADCoPVPbQsvoAAAAAAAAACAnwEfqgAB8WgHjAAAAABJRU5ErkJggg==~,
              'AUTOCROP_ERROR_BLANK: Image looks blank' ],
            [ qq~iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAIAAACQkWg2AAAABGdBTUEAALGPC/xhBQAAACpJREFUKM9jfOVsyoANeKXKYRVnYiARjGogBrBEOO3HKnFcRHA0lOinAQAwPgSWeitpNwAAAABJRU5ErkJggg==~,
              'AUTOCROP_ERROR_NOCROP: Nothing to crop' ],
            [ qq~iVBORw0KGgoAAAANSUhEUgAAAR8AAAEfCAAAAABdPJ2RAAADr0lEQVR42u3dQXKcMBAFUDmVG3JOnTG5wJT43TALS087xzEz9apVnxYgfv4NYzH+IODDhw8fPnz48DH48OHDhw8fPnz4GHz48OHDhw8fPgafYPxd/fKqHm1++vN5/1PwsfPT71aH7n5r9WN+8eHDh8/m+R7kXx7JM47r0fyf73xr9WN+8eHDh88Z+R5k+Fg07nk3H5weXNUePf/W6sf84sOHD58T8708Vi33bObtuD8vUD/mFx8+fPjI928c9GPjnl9VH9XwnurH/OLDhw8fo5nv3RRdLeFf92lfXsJ/NfvVDx8+fPjw2TXfy6vg+Y3z71yUf+dbqx8+fPjw4bPN+Pni/rSr6+/lxn3Gh1Y/5hcfPnz46N/fSe2P/zirx5xxA16+v657QqB++PDhw4fPrvl+fUrtq9pddxM23x7n4TY36ocPHz58+Gwzluvz+QJ7ObUfRnL3gv2ofmv1Y37x4cOHz3b5/rAdL19/H4vmfLzyCeVFBPXDhw8fPnx+4yjsP5/vJzfv/y6I5O6zc5f6Mb/48OHDR/9e7ZKDtO+24+WufLx5aPVjfvHhw4fPGf17nqLle93ztfT8QkC+3736Mb/48OHD5+D+/YoDutyq59ffr+rndR+2Uz/mFx8+fPic0b/nL4HJb2TPe/vgOnqQ4eVzFPVjfvHhw4fP5vkedN5BJAfvkJn3GV7eybbb6asf84sPHz58fv8orM+XO/Zyy13ekfbh9QD5bn7x4cOHj/496N+DU4C8Yw867254X+rH/OLDhw+fc/P94VY2wQPzqwfYg5gv3+RXXm5QP3z48OHDZ7t8z9fnH95NX74vL/ig7h3z6sf84sOHD5/N833cB+YqkrvJHCwN5K16+Zjqx/ziw4cPn98/6s+/l7e56d419zCn82fu5Lv5xYcPHz4n9u/dbeHLpwDBPz68a87+deYXHz58+Ojfu+Odp+XKI7+J3/V384sPHz58Du7fy3kbvBwuf11M/uqa0fwg9WN+8eHDh8+J+T7ibre8nXz+Ca9eHRjVNl798OHDhw+fXfM96LWDtC8vlAfPqucvfu928+qHDx8+fPhsnu/dcd3/VH45XL5QUN7RRv3w4cOHDx/5HnTe3cX3cR/eqzOB2fw79WN+8eHDh89R+V5+tqwc7N0b4Fdt/FQ/5hcfPnz4yPf7LM5Hfi9csDVe3tt3961XP+YXHz58+GwzvvL8u/rhY/Dhw4cPHz58+PAx+PDhw4cPHz58+CDgw4cPHz58+Bw2/gN2HPiplrUdygAAAABJRU5ErkJggg==~,
              { bottom => 259, left => 28, right => 259, top => 28} ],
            [
                qq~iVBORw0KGgoAAAANSUhEUgAAABAAAAAMCAIAAADkharWAAAAJ0lEQVQokWP8P5MBHaT9xxBCABbilUIA4///hBUhAyaSVI9qGDQaAGx7B3j5vR/PAAAAAElFTkSuQmCC~,
                { top => 0, left => 0, bottom => 2, right => 6 },
                { colour => '#FFFFFF' },
                'corner-0.png',
            ],
            [
                qq~iVBORw0KGgoAAAANSUhEUgAAAAwAAAAQCAIAAACtAwlQAAAAKklEQVQokWP8//8/Ax4wi5GBgYEJnwoYoJ+itP/EmsRIwHdEWTeqiARFAOYSCBmtR8ZmAAAAAElFTkSuQmCC~,
                { top => 0, left => 10, bottom => 6, right => 12 },
                { colour => '#FFFFFF' },
                'corner-1.png',
            ],
            [
                qq~iVBORw0KGgoAAAANSUhEUgAAABAAAAAMCAIAAADkharWAAAAI0lEQVQokWP8//8/AymAiSTVoxoGjQYWolTNYiRaA5JSCAAAJSoET+m19gkAAAAASUVORK5CYII=~,
                { top => 10, left => 10, bottom => 12, right => 16 },
                { colour => '#FFFFFF' },
                'corner-2.png',
            ],
            [
                qq~iVBORw0KGgoAAAANSUhEUgAAAAwAAAAQCAIAAACtAwlQAAAAIElEQVQokWP8//8/AyHARFDFqCISFM1ipKJ1hAyjs+8A5pYEU3IuMiAAAAAASUVORK5CYII=~,
                { top => 10, left => 0, bottom => 16, right => 2 },
                { colour => '#FFFFFF' },
                'corner-3.png',
            ],
            [
                qq~iVBORw0KGgoAAAANSUhEUgAAABAAAAAMCAIAAADkharWAAAAJUlEQVQokWP8//8/Ax4wixFNgJGABgxtxGlAAkwkqR7VMGg0AABpKgpDN2woWQAAAABJRU5ErkJggg==~,
                { top => 0, left => 10, bottom => 2, right => 16 },
                { colour => '#FFFFFF' },
                'corner-4.png',
            ],
            [
                qq~iVBORw0KGgoAAAANSUhEUgAAAAwAAAAQCAIAAACtAwlQAAAAI0lEQVQokWP8//8/AyHARFDFqCJqKprFSBWTZjESZx01FQEAwkIEU1FuiggAAAAASUVORK5CYII=~,
                { top => 10, left => 10, bottom => 16, right => 12 },
                { colour => '#FFFFFF' },
                'corner-5.png',
            ],
            [
                qq~iVBORw0KGgoAAAANSUhEUgAAABAAAAAMCAIAAADkharWAAAAKUlEQVQokWP8//8/AymAiSTVoxoGjQYWhlmMCF4a4VhHtWEWI4p+bAAAzP4GTWAYD/8AAAAASUVORK5CYII=~,
                { top => 10, left => 0, bottom => 12, right => 6 },
                { colour => '#FFFFFF' },
                'corner-6.png',
            ],
            [
                qq~iVBORw0KGgoAAAANSUhEUgAAAAwAAAAQCAIAAACtAwlQAAAALElEQVQokWP8P5OBgYGBIe0/A27AhEeOVorwOohYkxj//ydgDLEmjSoiThEAsD0HfjYvg2kAAAAASUVORK5CYII=~,
                { top => 0, left => 0, bottom => 6, right => 2 },
                { colour => '#FFFFFF' },
                'corner-7.png',
            ],
            [
                qq~iVBORw0KGgoAAAANSUhEUgAAABAAAAAMCAIAAADkharWAAAAKElEQVQokWP8//8/AymAiSTVoxoGjQYWnDKzGFG4adAEwfh/Jmk2AAC79gauUy88rAAAAABJRU5ErkJggg==~,
                { top => 10, left => 0, bottom => 12, right => 16 },
                { colour => '#FFFFFF' },
                'edge-10.png',
            ],
            [
                qq~iVBORw0KGgoAAAANSUhEUgAAAAwAAAAQCAIAAACtAwlQAAAAIUlEQVQokWP4P5PhPyHAxEAEGAGKZjHS1TrqKUr7Ty/rAIwoJJZ0IUEUAAAAAElFTkSuQmCC~,
                { top => 0, left => 0, bottom => 16, right => 2 },
                { colour => '#FFFFFF' },
                'edge-11.png',
            ],
            [
                qq~iVBORw0KGgoAAAANSUhEUgAAABAAAAAMCAIAAADkharWAAAAJ0lEQVQokWP8P5OBJMD4//9/7DKzGFG4af8JacABmEhz0KiGwaIBAKT1CahC/25rAAAAAElFTkSuQmCC~,
                { top => 0, left => 0, bottom => 2, right => 16 },
                { colour => '#FFFFFF' },
                'edge-12.png',
            ],
            [
                qq~iVBORw0KGgoAAAANSUhEUgAAAAwAAAAQCAIAAACtAwlQAAAAKElEQVQokWP8//8/A34wi5GJgAoGBgYGhpGtaBYjXa2jnqK0/1S1DgBpLgW4YFYc1gAAAABJRU5ErkJggg==~,
                { top => 0, left => 10, bottom => 16, right => 12 },
                { colour => '#FFFFFF' },
                'edge-13.png',
            ],
            [
                qq~iVBORw0KGgoAAAANSUhEUgAAABAAAAAMCAIAAADkharWAAAAKElEQVQokWP8//8/AymAiSTVoxoGjQYWBHMWI4pMGvYUwPh/Jmk2AADZ9gau3Yny6gAAAABJRU5ErkJggg==~,
                { top => 10, left => 0, bottom => 12, right => 16 },
                { colour => '#FFFFFF' },
                'edge-14.png',
            ],
            [
                qq~iVBORw0KGgoAAAANSUhEUgAAAAwAAAAQCAIAAACtAwlQAAAAJElEQVQokWP4P5PhPyHAxEAEIF7RLEZqmURnRWn/6WrdUFQEAP43JJYqjZKIAAAAAElFTkSuQmCC~,
                { top => 0, left => 0, bottom => 16, right => 2 },
                { colour => '#FFFFFF' },
                'edge-15.png',
            ],
            [
                qq~iVBORw0KGgoAAAANSUhEUgAAABAAAAAMCAIAAADkharWAAAAKUlEQVQokWP8P5OBJMD4//9/KHMWI4pM2n9M1agaiANMpDloVMNg0QAAwvUJqEDBgA8AAAAASUVORK5CYII=~,
                { top => 0, left => 0, bottom => 2, right => 16 },
                { colour => '#FFFFFF' },
                'edge-8.png',
            ],
            [
                qq~iVBORw0KGgoAAAANSUhEUgAAAAwAAAAQCAIAAACtAwlQAAAAKklEQVQokWP8//8/A34wi5GJgAoGBgYGBqoomsVILZPorCjtP12tG7SKANs9BbiJI/h3AAAAAElFTkSuQmCC~,
                { top => 0, left => 10, bottom => 16, right => 12 },
                { colour => '#FFFFFF' },
                'edge-9.png',
            ],
            [
                qq~iVBORw0KGgoAAAANSUhEUgAAABAAAAAMCAIAAADkharWAAAAL0lEQVQokWP8//8/AymAiSTVoxqIBCwI5ixGFJk07PHDiB5xaNowNGNoIARI9gMACD4ND4WozAoAAAAASUVORK5CYII=~,
                { top => 8, left => 3, bottom => 10, right => 12 },
                { colour => '#FFFFFF' },
                'pair-0.png',
            ],
            [
                qq~iVBORw0KGgoAAAANSUhEUgAAAAwAAAAQCAIAAACtAwlQAAAALklEQVQokWP8//8/AyHARFAFGYpmMVLFJNzGkOEmohSl4QwwmliHGzAOWNzhBgBZZwi0sacWrAAAAABJRU5ErkJggg==~,
                { top => 3, left => 2, bottom => 12, right => 4 },
                { colour => '#FFFFFF' },
                'pair-1.png',
            ],
            [
                qq~iVBORw0KGgoAAAANSUhEUgAAABAAAAAMCAIAAADkharWAAAAMklEQVQokWP8//8/AymAiSTVDAwMLCi8WYxYlKShOIERp5PQNMO04daAA5Dsh1ENxAAAZf8ND7LGVuEAAAAASUVORK5CYII=~,
                { top => 2, left => 4, bottom => 4, right => 13 },
                { colour => '#FFFFFF' },
                'pair-2.png',
            ],
            [
                qq~iVBORw0KGgoAAAANSUhEUgAAAAwAAAAQCAIAAACtAwlQAAAALElEQVQokWP8//8/AyHARFAF/RTNYqSrdYQVwRxEJ+sYGBjS/pNgEiN9IxgAx5AItOUTAeMAAAAASUVORK5CYII=~,
                { top => 4, left => 8, bottom => 13, right => 10 },
                { colour => '#FFFFFF' },
                'pair-3.png',
            ],
            [
                qq~iVBORw0KGgoAAAANSUhEUgAAABAAAAAMCAIAAADkharWAAAAK0lEQVQokWP8//8/AymAiSTVoxqIBCw4ZWYxonDT/mPTgKYIVSkEMNI8pgFAjAoV2wVhRQAAAABJRU5ErkJggg==~,
                { top => 8, left => 4, bottom => 10, right => 13 },
                { colour => '#FFFFFF' },
                'pair-4.png',
            ],
            [
                qq~iVBORw0KGgoAAAANSUhEUgAAAAwAAAAQCAIAAACtAwlQAAAAK0lEQVQokWP8//8/AyHARFAFTRTNYqSrdcQqwu0s6luXhi9yiDKJkb4RDAD6pQi0LRUvCQAAAABJRU5ErkJggg==~,
                { top => 4, left => 2, bottom => 13, right => 4 },
                { colour => '#FFFFFF' },
                'pair-5.png',
            ],
            [
                qq~iVBORw0KGgoAAAANSUhEUgAAABAAAAAMCAIAAADkharWAAAALklEQVQokWP8//8/AymAiSTVDAwMLOgCsxixqEpDuIIFp9I07E5lpLkfRjUQAwBjBAoVV5fPbQAAAABJRU5ErkJggg==~,
                { top => 2, left => 3, bottom => 4, right => 12 },
                { colour => '#FFFFFF' },
                'pair-6.png',
            ],
            [
                qq~iVBORw0KGgoAAAANSUhEUgAAAAwAAAAQCAIAAACtAwlQAAAALUlEQVQokWP8//8/AyHARFAF5YpmMVLROphh9HB42n8iFFHPOiTAOFjiDgkAAC6wCLTQK85ZAAAAAElFTkSuQmCC~,
                { top => 3, left => 8, bottom => 12, right => 10 },
                { colour => '#FFFFFF' },
                'pair-7.png',
            ],
            [
                qq~iVBORw0KGgoAAAANSUhEUgAAAAwAAAAQCAIAAACtAwlQAAAAJklEQVQoz2P4jx/MZPj//z8TAxGAWopmMdLVOuopSvs/RB1OTUUA7A0kllsP0+kAAAAASUVORK5CYII=~,
                { top => 0, left => 10, bottom => 16, right => 12 },
                { colour => '#FFFFFF' },
                'edge-1.png',
            ],
            [
                qq~iVBORw0KGgoAAAANSUhEUgAAABAAAAAMCAIAAADkharWAAAALUlEQVQokWP8//8/AwTMYmRABmn/GbABxv8zsYrjBIwIG4gDTKSZP6phsGgAAGlZCahDtVplAAAAAElFTkSuQmCC~,
                { top => 0, left => 0, bottom => 2, right => 16 },
                { colour => '#FFFFFF' },
                'edge-0.png',
            ],
            [
                qq~iVBORw0KGgoAAAANSUhEUgAAABAAAAAMCAIAAADkharWAAAAJ0lEQVQokWP8//8/AymAiSTVoxoGjQYWhlmMJGlgxJk00AxKgyoDANShCK6taGCFAAAAAElFTkSuQmCC~,
                { top => 10, left => 0, bottom => 12, right => 16 },
                { colour => '#FFFFFF' },
                'edge-2.png',
            ],
            [
                qq~iVBORw0KGgoAAAANSUhEUgAAAAwAAAAQCAIAAACtAwlQAAAAJUlEQVQokWP4/////5kM//ECJgYiwHBXNIuRrtZRT1HafzpaBwCWVySWgNM5lQAAAABJRU5ErkJggg==~,
                { top => 0, left => 0, bottom => 16, right => 2 },
                { colour => '#FFFFFF' },
                'edge-3.png',
            ],
            [
                qq~iVBORw0KGgoAAAANSUhEUgAAABAAAAAMCAIAAADkharWAAAAK0lEQVQokWP8//8/A1YwixGFmwZVxvh/Jnb1uAAjThtwACbSzB/VMFg0AABLWQmoRV0FSgAAAABJRU5ErkJggg==~,
                { top => 0, left => 0, bottom => 2, right => 16 },
                { colour => '#FFFFFF' },
                'edge-4.png',
            ],
            [
                qq~iVBORw0KGgoAAAANSUhEUgAAAAwAAAAQCAIAAACtAwlQAAAAI0lEQVQokWP4jx/MZPj//z8TAxFgxCuaxTj43ESUojQqRjAAef4kllx2w8wAAAAASUVORK5CYII=~,
                { top => 0, left => 10, bottom => 16, right => 12 },
                { colour => '#FFFFFF' },
                'edge-5.png',
            ],
            [
                qq~iVBORw0KGgoAAAANSUhEUgAAABAAAAAMCAIAAADkharWAAAAJ0lEQVQokWP8//8/AymAiSTVoxoGjQYWhlmMJGlgRCQNNJ1p2JMMAPKhCK6M8wH0AAAAAElFTkSuQmCC~,
                { top => 10, left => 0, bottom => 12, right => 16 },
                { colour => '#FFFFFF' },
                'edge-6.png',
            ],
            [
                qq~iVBORw0KGgoAAAANSUhEUgAAAAwAAAAQCAIAAACtAwlQAAAAJ0lEQVQokWP4/////5kM//ECJgYiAJGKZjFSyyQ6K0r7T1frhqgiAAh1JJZQEWFZAAAAAElFTkSuQmCC~,
                { top => 0, left => 0, bottom => 16, right => 2 },
                { colour => '#FFFFFF' },
                'edge-7.png',
            ],
            [
                qq~iVBORw0KGgoAAAANSUhEUgAAABAAAAAMCAIAAADkharWAAAAJklEQVQokWP8//8/AymAiSTVg1MDC4I5ixFFJg17YDCOxFAiWQMA4eMIE7+tPP0AAAAASUVORK5CYII=~,
                { top => 5, left => 3, bottom => 6, right => 8 },
                { colour => '#FFFFFF' },
                'line-0.png',
            ],
            [
                qq~iVBORw0KGgoAAAANSUhEUgAAAAwAAAAQCAIAAACtAwlQAAAAIklEQVQokWP8//8/AyHARFAFJYpmMdLVOvIUMQ58OA0JRQCPjwa0GrW0sQAAAABJRU5ErkJggg==~,
                { top => 3, left => 6, bottom => 8, right => 7 },
                { colour => '#FFFFFF' },
                'line-1.png',
            ],
            [
                qq~iVBORw0KGgoAAAANSUhEUgAAABAAAAAMCAIAAADkharWAAAAJElEQVQokWP8//8/AymAiSTVw0QDC06ZWYwo3DRoYDKOxGAFAM82CBP2iSSEAAAAAElFTkSuQmCC~,
                { top => 6, left => 8, bottom => 7, right => 13 },
                { colour => '#FFFFFF' },
                'line-2.png',
            ],
            [
                qq~iVBORw0KGgoAAAANSUhEUgAAAAwAAAAQCAIAAACtAwlQAAAAIElEQVQokWP8//8/AyHARFDFyFM0i5Gu1pGtiJG+EQwA+RQGtM3ADDIAAAAASUVORK5CYII=~,
                { top => 8, left => 5, bottom => 13, right => 6 },
                { colour => '#FFFFFF' },
                'line-3.png',
            ],

        ],
        tga => [
            [ qq~AAEJAAABASAAAAAAUAAyAAgAAAAA/wEBAf8CAgL/AwMD/wQEBP8FBQX/BgYG/wcHB/8ICAj/CQkJ/woKCv8LCwv/DAwM/w0NDf8ODg7/Dw8P/xAQEP8RERH/EhIS/xMTE/8UFBT/FRUV/xYWFv8XFxf/GBgY/xkZGf8aGhr/Gxsb/xwcHP8dHR3/Hh4e/x8fH/8gICD/ISEh/yIiIv8jIyP/JCQk/yUlJf8mJib/Jycn/ygoKP8pKSn/Kioq/ysrK/8sLCz/LS0t/y4uLv8vLy//MDAw/zExMf8yMjL/MzMz/zQ0NP81NTX/NjY2/zc3N/84ODj/OTk5/zo6Ov87Ozv/PDw8/z09Pf8+Pj7/Pz8//0BAQP9BQUH/QkJC/0NDQ/9ERET/RUVF/0ZGRv9HR0f/SEhI/0lJSf9KSkr/S0tL/0xMTP9NTU3/Tk5O/09PT/9QUFD/UVFR/1JSUv9TU1P/VFRU/1VVVf9WVlb/V1dX/1hYWP9ZWVn/Wlpa/1tbW/9cXFz/XV1d/15eXv9fX1//YGBg/2FhYf9iYmL/Y2Nj/2RkZP9lZWX/ZmZm/2dnZ/9oaGj/aWlp/2pqav9ra2v/bGxs/21tbf9ubm7/b29v/3BwcP9xcXH/cnJy/3Nzc/90dHT/dXV1/3Z2dv93d3f/eHh4/3l5ef96enr/e3t7/3x8fP99fX3/fn5+/39/f/+AgID/gYGB/4KCgv+Dg4P/hISE/4WFhf+Ghob/h4eH/4iIiP+JiYn/ioqK/4uLi/+MjIz/jY2N/46Ojv+Pj4//kJCQ/5GRkf+SkpL/k5OT/5SUlP+VlZX/lpaW/5eXl/+YmJj/mZmZ/5qamv+bm5v/nJyc/52dnf+enp7/n5+f/6CgoP+hoaH/oqKi/6Ojo/+kpKT/paWl/6ampv+np6f/qKio/6mpqf+qqqr/q6ur/6ysrP+tra3/rq6u/6+vr/+wsLD/sbGx/7Kysv+zs7P/tLS0/7W1tf+2trb/t7e3/7i4uP+5ubn/urq6/7u7u/+8vLz/vb29/76+vv+/v7//wMDA/8HBwf/CwsL/w8PD/8TExP/FxcX/xsbG/8fHx//IyMj/ycnJ/8rKyv/Ly8v/zMzM/83Nzf/Ozs7/z8/P/9DQ0P/R0dH/0tLS/9PT0//U1NT/1dXV/9bW1v/X19f/2NjY/9nZ2f/a2tr/29vb/9zc3P/d3d3/3t7e/9/f3//g4OD/4eHh/+Li4v/j4+P/5OTk/+Xl5f/m5ub/5+fn/+jo6P/p6en/6urq/+vr6//s7Oz/7e3t/+7u7v/v7+//8PDw//Hx8f/y8vL/8/Pz//T09P/19fX/9vb2//f39//4+Pj/+fn5//r6+v/7+/v//Pz8//39/f/+/v7//////wAAAADP/8//z//P/8//z//P/8//z//P/8//z//P/8//z//P/8//z/+g/wNWAD7+hv8CVwBPoP+g/wPsGACOhf8DtgAM46D/of8DtAAI14P/A/UgAI+h/6L/A2IANfyC/wN2ADL8of+i/wPyHwCDgf8D0QQCy6L/o/8HvwEFz/04AG2j/6T/Bm4ALY8AG/Kj/6T/AfYnggAArKT/pf8DyQIASqX/pf8As4EAASX1pP+k/wX0HwANAGyk/6T/BnIAMM4GAb2j/6P/CM4DAsr/hwAf8aL/ov8D/DQAbIH/A/w5AGKi/6L/A5AAG/GC/wPbCgCzof+h/wPjDQCshP8DlAAY7aD/of8CTwBMhf8D/kUAV6D/z//P/8//z//P/8//z//P/8//z//P/8//z//P/8//AAAAAAAAAABUUlVFVklTSU9OLVhGSUxFLgA=~,
              { bottom => 32, left => 33, right => 47, top => 15} ],
            [ qq~AAEJAAABASAAAAAAUAAyAAgAAAAA/wEBAf8CAgL/AwMD/wQEBP8FBQX/BgYG/wcHB/8ICAj/CQkJ/woKCv8LCwv/DAwM/w0NDf8ODg7/Dw8P/xAQEP8RERH/EhIS/xMTE/8UFBT/FRUV/xYWFv8XFxf/GBgY/xkZGf8aGhr/Gxsb/xwcHP8dHR3/Hh4e/x8fH/8gICD/ISEh/yIiIv8jIyP/JCQk/yUlJf8mJib/Jycn/ygoKP8pKSn/Kioq/ysrK/8sLCz/LS0t/y4uLv8vLy//MDAw/zExMf8yMjL/MzMz/zQ0NP81NTX/NjY2/zc3N/84ODj/OTk5/zo6Ov87Ozv/PDw8/z09Pf8+Pj7/Pz8//0BAQP9BQUH/QkJC/0NDQ/9ERET/RUVF/0ZGRv9HR0f/SEhI/0lJSf9KSkr/S0tL/0xMTP9NTU3/Tk5O/09PT/9QUFD/UVFR/1JSUv9TU1P/VFRU/1VVVf9WVlb/V1dX/1hYWP9ZWVn/Wlpa/1tbW/9cXFz/XV1d/15eXv9fX1//YGBg/2FhYf9iYmL/Y2Nj/2RkZP9lZWX/ZmZm/2dnZ/9oaGj/aWlp/2pqav9ra2v/bGxs/21tbf9ubm7/b29v/3BwcP9xcXH/cnJy/3Nzc/90dHT/dXV1/3Z2dv93d3f/eHh4/3l5ef96enr/e3t7/3x8fP99fX3/fn5+/39/f/+AgID/gYGB/4KCgv+Dg4P/hISE/4WFhf+Ghob/h4eH/4iIiP+JiYn/ioqK/4uLi/+MjIz/jY2N/46Ojv+Pj4//kJCQ/5GRkf+SkpL/k5OT/5SUlP+VlZX/lpaW/5eXl/+YmJj/mZmZ/5qamv+bm5v/nJyc/52dnf+enp7/n5+f/6CgoP+hoaH/oqKi/6Ojo/+kpKT/paWl/6ampv+np6f/qKio/6mpqf+qqqr/q6ur/6ysrP+tra3/rq6u/6+vr/+wsLD/sbGx/7Kysv+zs7P/tLS0/7W1tf+2trb/t7e3/7i4uP+5ubn/urq6/7u7u/+8vLz/vb29/76+vv+/v7//wMDA/8HBwf/CwsL/w8PD/8TExP/FxcX/xsbG/8fHx//IyMj/ycnJ/8rKyv/Ly8v/zMzM/83Nzf/Ozs7/z8/P/9DQ0P/R0dH/0tLS/9PT0//U1NT/1dXV/9bW1v/X19f/2NjY/9nZ2f/a2tr/29vb/9zc3P/d3d3/3t7e/9/f3//g4OD/4eHh/+Li4v/j4+P/5OTk/+Xl5f/m5ub/5+fn/+jo6P/p6en/6urq/+vr6//s7Oz/7e3t/+7u7v/v7+//8PDw//Hx8f/y8vL/8/Pz//T09P/19fX/9vb2//f39//4+Pj/+fn5//r6+v/7+/v//Pz8//39/f/+/v7//////wAAAADP/8//z//P/8//z//P/8//z//P/8//z//P/8//z//P/8//z/+g/wNWAD7+hv8CVwBPoP+g/wPsGACOhf8DtgAM46D/of8DtAAI14P/A/UgAI+h/6L/A2IANfyC/wN2ADL8of+i/wPyHwCDgf8D0QQCy6L/o/8HvwEFz/04AG2j/6T/Bm4ALY8AG/Kj/6T/AfYnggAArKT/pf8DyQIASqX/pf8As4EAASX1pP+k/wX0HwANAGyk/6T/BnIAMM4GAb2j/6P/CM4DAsr/hwAf8aL/ov8D/DQAbIH/A/w5AGKi/6L/A5AAG/GC/wPbCgCzof+h/wPjDQCshP8DlAAY7aD/of8CTwBMhf8D/kUAV6D/z//P/8//z//P/8//z//P/8//z//P/8//z//P/8//AAAAAAAAAABUUlVFVklTSU9OLVhGSUxFLgA=~,
              { bottom => 32, left => 33, right => 47, top => 15} ],
        ],
    }; 

    foreach my $type (keys %{$images}) {
         foreach my $img (@{$images->{$type}}) {
             $img->[0] = decode_base64($img->[0]);
         }
    }

    return $images;
}
