//////////////////////////////////
//// XML Parser / Generator //////
//// Author: jgrant         //////
//// Date: Mar 2011         //////
//////////////////////////////////


\d .xml

/ XML Parse

p:{
  b:where x in "<>";
  b:$["?"=x 1+first b;2 _ b;b];
  o:b i:2*j:til `int$count[b]%2;
  c:b i+1;
  e:"/"=x 1+o;
  m:"/"=x -1+c;
  a:1 _' b _ x;
  p:prev last each {[a;x;m;e]$[m;a;e;-1 _ a;a,x]}\[0N;j;m;e];
  ne:where not e;
  d:ne group p ne;
  :{[a;d;m;e;i]
    (n[0;0];
     1 _  1 _' -1 _' (!). n:"S= "0:$[m i;-1 _ a 2*i;a 2*i];
     $[m i;();e i+1;a 1+2*i;.z.s[a;d;m;e] each d i]
    )}[a;d;m;e] each d 0N}

/ XML Generate

/header
h:"<?xml version=\"1.0\" encoding=\"UTF-8\"?>"

/ attribute dictionary to string
ad:{[d]raze " ",'string[key d],'"=",'"\"",'{$[10h=type x;x;string x]}'[value d],'"\""}

/ format float - add a .0 if the float happens to be a whole number
ff:{s,$["." in s:string x;"";".0"]}

el:{[n;d;c]   / Name attributeDict Content
  $[count c;
    "<",string[n],$[count d;ad d;""],">",t[c],"</",string[n],">";
    "<",string[n],$[count d;ad d;""],"/>"]}


t:{
  $[0=t:type x;
     $[(3=count x) and -11h=type first x;
       el . x;
       (all 3=count each x);
       raze el .' x;
       '`shape];
    10h=t;x;
    -9h=t;ff x;
    0>t;string x;
    9h=t;" " sv ff each x;
    t within 1 20h;" " sv string x;
    '`type]}

g:{h,t x}

prse:{[jg]((1#jg[0;])!enlist ((1_jg[0;])[0];
	{[x;y](1#y[x;])!(enlist (();
		{[x;y]
			if[x in (0;1;2);:(first -1#(1_y[x;]));:()];
			z:(1_y[x;])[1];
				{[z;x]
				if[x=0;:(1#z[0;0])!(enlist (();first -1#z[0;]));:()];
				(enlist z[x;0])!enlist (z[x;1];(
					{[r]
						(1#r)!(enlist (();first -1#r))}'[z[x;2]]))}[z;] each (til count z)
		}[x;y]))
	}[;(1_jg[0;])[1]] each (til count (1_jg[0;])[1])))}



/prse:{[jg]((1#jg[0;])!enlist ((1_jg[0;])[0];{[x;y]   (1#y[x;])!(enlist (();{[x;y]if[x in (0;1;2);:(first -1#(1_y[x;]));:()];z:(1_y[x;])[1];{[z;x]if[x=0;:(1#z[0;0])!(enlist (();first -1#z[0;]));:()];(enlist z[x;0])!enlist (z[x;1];({[r](1#r)!(enlist (();first -1#r))}'[z[x;2]]))}[z;] each (til count z)}[x;y]))}[;(1_jg[0;])[1]] each (til count (1_jg[0;])[1])))}

