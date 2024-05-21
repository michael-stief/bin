
<?php
function randomPassword( $len = 10, $ucfirst = true, $spchar = true ){
	/* Programmed by Christian Haensel
	 * christian@chftp.com
	 * http://www.chftp.com
	 *
	 * Exclusively published on weberdev.com.
	 * If you like my scripts, please let me know or link to me.
	 * You may copy, redistribute, change and alter my scripts as
	 * long as this information remains intact.
	 *
	 * Modified by Josh Hartman on 2010-12-30.
	 * Last modified: 2023-03-01
	 * Thanks to JKDos for suggesting improvements.
	 */
	if ( $len >= 8 && ( $len % 2 ) !== 0 ) { // Length parameter must be greater than or equal to 8, and a multiple of 2
		$len = 8;
	}
	$length = $len - 2; // Makes room for a two-digit number on the end
	$conso = array( 'b', 'c', 'd', 'f', 'g', 'h', 'j', 'k', 'l', 'm', 'n', 'p', 'r', 's', 't', 'v', 'w', 'x', 'y', 'z' );
	$vowel = array( 'a', 'e', 'i', 'o', 'u' );
	$spchars = array( '!', '@', '#', '$', '%', '^', '&', '*', '-', '+', '?', '=', '~' );
	$password = '';
	$max = $length / 2;
	for ( $i = 1; $i <= $max; $i ++ ) {
		$password .= $conso[ random_int( 0, 19 ) ];
		$password .= $vowel[ random_int( 0, 4 ) ];
	}
	if ( $spchar == true ) {
		$password = substr( $password, 0, - 1 ) . $spchars[ random_int( 0, 12 ) ];
	}
	$password .= random_int( 10, 99 );
	if ( $ucfirst == true ) {
		$password = ucfirst( $password );
	}
	return $password;
}

echo randomPassword();
