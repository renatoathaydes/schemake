String identityString(String s) => s;

String quote(String s) => "'$s'";

String dollar(String s) => "\$$s";

String quoteAndDollar(String s) => '"\$$s"';

String nullable(String s) => "$s?";

String array(String s) => "List<$s>";
