// better looking in github render
## Title as I would like displayed
{ref to this div; other ref to this div}
\notnumbered

// not render as nice in github md render, but valid
## This is valid too title as I would like displayed{ref to this div, other ref to this div}\notnumbered

// weird, but valid, still would not place on specs
## This\notnumbered is valid too title as I would like displayed{ref to this div, other ref to this div}\notnumbered

//this is not valid
\chapter\notnumbered{Title to display}{ref,otherref}

//This is how we use \chapter
\chapter{Title to display\notnumbered}{ref,otherref}

//this is another way
\div{level}{title to display}{ref,otherref}

For now level can be from 1 to 6

level can be relative for now with \relativediv (maybe later with div{/level} or {+level})
