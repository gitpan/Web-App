use ExtUtils::MakeMaker;

WriteMakefile(
	NAME => "Web::App",
	VERSION_FROM => "lib/Web/App.pm",
	'dist' => { COMPRESS=>"gzip", SUFFIX=>"gz" },
	AUTHOR => 'Ivan Baktsheev <dot.and.thing@gmail.com>',
	PREREQ_PM => {
		'Class::Easy'     => 0.02, # try_to_use support
		'XML::LibXML'     => 1.60,
		'Data::Dump::XML' => 1,
		'XML::LibXSLT'    => 1.60,
	}
);
