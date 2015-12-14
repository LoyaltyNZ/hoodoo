window.addEventListener( 'load', addTOC );

function addTOC()
{
  var container = document.getElementById( 'toc' );
  if ( container === null ) return;

  var outerListType = 'ol';
  var innerListType = 'ul';
  var range         = document.createRange();

  range.selectNodeContents( container );
  range.deleteContents();

  var outermostList = document.createElement( outerListType );

  container.appendChild( outermostList );

  var currentLevel   = 'H2';
  var sections       = { H2: { recentListNode: outermostList } };
  var headings       = document.querySelectorAll( 'article section h1, article section h2, article section h3, article section h4, article section h5, article section h6' );
  var count          = headings.length;

  for ( var i = 0; i < count; ++i )
  {
    var heading      = headings[ i ];
    var headingText  = heading.textContent || heading.innerText;
    var headingLevel = heading.tagName.toUpperCase();

    if ( headingLevel > currentLevel )
    {
      var listNode = document.createElement( innerListType );

      sections[ headingLevel ] = sections[ headingLevel ] || {}
      sections[ headingLevel ].recentListNode = listNode;
      sections[ currentLevel ].recentItemNode.appendChild( listNode );
    }

    currentLevel = headingLevel;

    var listNode = sections[ headingLevel ].recentListNode;
    var itemNode = document.createElement( 'li' );
    var anchor   = 'heading_number_' + ( i + 1 );

    heading.id = anchor;

    itemNode.innerHTML = '<a href="#' + anchor + '">' + headingText + '</a>';
    listNode.appendChild( itemNode );
    sections[ headingLevel ].recentItemNode = itemNode;
  }
}
