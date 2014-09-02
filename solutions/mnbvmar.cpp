#include <bits/stdc++.h>
#define $ complex<double>
#define C vector<$>
#define I int
#define D double
#define P pair<D,I>
#define Q pair<D,D>
#define E vector<D>
#define V vector<P>
#define W vector<Q>
#define S char*
#define Z(x)if(fread(&x,2,1,y)!=1)break;
#define B push_back
#define F(i,f,t)for(I i=f;i<t;i++)
#define _ return
#define J first
#define L second
const I K=75,O=16384;using namespace std;C R(C&i,I s,I o=0,I d=1){if(!s)_ C(1,i[o]);C l=R(i,s/2,o,d*2),h=R(i,s/2,o+d,d*2);C r(s*2);$ b=exp($(0,-M_PI/s)),f=1;F(k,0,s){r[k]=l[k]+f*h[k];r[k+s]=l[k]-f*h[k];f*=b;}_ r;}C T(C&i){_ R(i,i.size()/2);}char b[O];E U(S m){FILE*y;if(!(y=fopen(m,"r")))_ E();setvbuf(y,b,0,O);fseek(y,0,2);I z=ftell(y)/4-32;fseek(y,128,0);C p;F(i,0,z){short l,r;Z(l);Z(r);if(i&1)p.B($(0.5/O*le16toh(l),0));}p.resize(O);E h(O),n(O);p=T(p);F(j,0,O)h[j]=norm(p[j])/O;F(i,1,O-1)n[i]=(h[i-1]+h[i+1]+h[i]*8)/10;fclose(y);_ n;}W G(E&d){V p;F(i,3,O/2-3)if(d[i]==*max_element(d.begin()+i-3,d.begin()+i+4))p.B({d[i],i});sort(p.begin(),p.end(),greater<P>());W r;F(i,3,K+3)r.B({D(p[i].L)/O*22050,log(p[i].J)+10});D s=0;F(i,0,K)s+=r[i].L;F(i,0,K)r[i].L/=s;_ r;}char m[O];I X(S p,W&r){E t(O),h(t);I f=0;while(1){sprintf(m,"%s%d.wav",p,f++);h=U(m);if(!h.size())break;F(j,0,O)t[j]+=h[j];}F(j,0,O)t[j]/=f;r=G(t);}D Y(W&a,W&b){D r=0;F(i,0,K){D d=b[i].L;F(j,0,K)if(abs((b[i].J-a[j].J)/b[i].J)<0.015)d=min(d,abs(b[i].L-a[j].L));r+=d;}_ r;}I H(S p,W&y,W&n){I f=0;while(1){sprintf(m,"%s%d.wav",p,f++);E h=U(m);if(!h.size())break;W p=G(h);D q=Y(p,y),r=Y(p,n);printf(abs(q-r)<=0.01?"?\n":q<r?"yes\n":"no\n");}}I main(){W y,n;X("train/yes",y);X("train/no",n);H("inputs/",y,n);}
