import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/advertisement_public_service.dart';
import '../services/auth_service.dart';

const _primary=Color(0xFF165B5D);
const _accent=Color(0xFFF46627);

class SponsoredAdvertisements extends StatefulWidget {
  const SponsoredAdvertisements({super.key,required this.placement,this.country});
  final String placement;
  final String? country;
  @override State<SponsoredAdvertisements> createState()=>_SponsoredAdvertisementsState();
}
class _SponsoredAdvertisementsState extends State<SponsoredAdvertisements> {
  List<PublicAdvertisement> ads=[];
  final Set<int> seen={};
  int current=0;
  @override void initState(){super.initState();_load();}
  @override void didUpdateWidget(covariant SponsoredAdvertisements oldWidget){
    super.didUpdateWidget(oldWidget);
    if(oldWidget.placement!=widget.placement || oldWidget.country!=widget.country){seen.clear();_load();}
  }
  Future<void> _load()async{
    try {final results=await AdvertisementPublicService.instance.load(widget.placement,country:widget.country);
      if(mounted){setState((){ads=results;current=0;});if(results.isNotEmpty)_track(results.first);}}
    catch (_){if(mounted)setState(()=>ads=[]);}
  }
  void _track(PublicAdvertisement ad){if(seen.add(ad.id))AdvertisementPublicService.instance.impression(ad.id);}
  void _open(PublicAdvertisement ad){
    AdvertisementPublicService.instance.click(ad.id);
    Navigator.push(context,MaterialPageRoute(builder:(_)=>_AdvertisementPosterPage(ad:ad)));
  }
  @override Widget build(BuildContext context){
    if(ads.isEmpty)return const SizedBox.shrink();
    final carousel=widget.placement=='homepage_carousel';
    return Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
      Row(children:[const Icon(Icons.campaign_outlined,color:_accent,size:18),const SizedBox(width:7),
        Text(carousel?'Sponsored':'Advertisement',style:const TextStyle(fontWeight:FontWeight.w700,fontSize:17,color:_primary)),
        const Spacer(),Text('Ad',style:TextStyle(fontSize:11,color:Theme.of(context).colorScheme.onSurfaceVariant))]),
      const SizedBox(height:12),
      if(carousel) SizedBox(height:286,child:PageView.builder(itemCount:ads.length,
        onPageChanged:(index){setState(()=>current=index);_track(ads[index]);},
        itemBuilder:(context,index)=>_AdCard(ad:ads[index],onTap:()=>_open(ads[index]))))
      else SizedBox(height:286,child:_AdCard(ad:ads.first,onTap:()=>_open(ads.first))),
      if(carousel && ads.length>1)Padding(padding:const EdgeInsets.only(top:10),child:Row(mainAxisAlignment:MainAxisAlignment.center,
        children:List.generate(ads.length,(index)=>Container(margin:const EdgeInsets.symmetric(horizontal:3),width:index==current?18:6,height:6,
          decoration:BoxDecoration(color:index==current?_primary:_primary.withValues(alpha:.18),borderRadius:BorderRadius.circular(10))))),),
    ]);
  }
}
class _AdCard extends StatelessWidget {
 const _AdCard({required this.ad,required this.onTap});
 final PublicAdvertisement ad;final VoidCallback onTap;
 @override Widget build(BuildContext context)=>Material(color:Theme.of(context).colorScheme.surface,borderRadius:BorderRadius.circular(20),
  child:InkWell(onTap:onTap,borderRadius:BorderRadius.circular(20),child:Container(
   decoration:BoxDecoration(border:Border.all(color:_primary.withValues(alpha:.14)),borderRadius:BorderRadius.circular(20)),
   padding:const EdgeInsets.all(12),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
    Expanded(child:Center(child:Image.network(AuthService.storageUrl(ad.imagePath),fit:BoxFit.contain,width:double.infinity,
      errorBuilder:(_,__,___)=>const Icon(Icons.broken_image_outlined,size:50)))),
    const SizedBox(height:10),Text(ad.title,maxLines:1,overflow:TextOverflow.ellipsis,style:const TextStyle(fontWeight:FontWeight.w700,fontSize:15)),
    const SizedBox(height:3),Text(ad.advertiser,maxLines:1,overflow:TextOverflow.ellipsis,style:TextStyle(fontSize:12,color:Theme.of(context).colorScheme.onSurfaceVariant)),
   ]))));
}
class _AdvertisementPosterPage extends StatelessWidget {
 const _AdvertisementPosterPage({required this.ad});final PublicAdvertisement ad;
 @override Widget build(BuildContext context)=>Scaffold(backgroundColor:const Color(0xFFF4EEE1),
  appBar:AppBar(title:const Text('Sponsored advertisement'),backgroundColor:_primary,foregroundColor:Colors.white),
  body:SafeArea(child:Column(children:[
   Expanded(child:InteractiveViewer(minScale:1,maxScale:4,child:Center(child:Image.network(AuthService.storageUrl(ad.imagePath),fit:BoxFit.contain,
     errorBuilder:(_,__,___)=>const Icon(Icons.broken_image_outlined,size:64))))),
   Padding(padding:const EdgeInsets.fromLTRB(20,12,20,20),child:Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[
    Text(ad.title,style:const TextStyle(fontSize:18,fontWeight:FontWeight.w800,color:_primary)),
    const SizedBox(height:4),Text(ad.advertiser),
    if(ad.description.isNotEmpty)Padding(padding:const EdgeInsets.only(top:8),child:Text(ad.description,maxLines:3,overflow:TextOverflow.ellipsis)),
    if(ad.actionType!='none' && ad.actionValue.isNotEmpty)Padding(padding:const EdgeInsets.only(top:12),child:FilledButton.icon(
      style:FilledButton.styleFrom(backgroundColor:_accent),onPressed:() async {
       await Clipboard.setData(ClipboardData(text:ad.actionValue));
       if (!context.mounted) return;
       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Contact or website copied')));
      },icon:const Icon(Icons.copy),label:Text('Copy ${ad.actionType=='website'?'website':'contact'}'))),
   ])),
  ])));
}
