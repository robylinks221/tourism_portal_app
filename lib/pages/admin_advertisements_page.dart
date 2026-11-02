import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/advertisement_admin_service.dart';
import '../services/auth_service.dart';

const _green=Color(0xFF165B5D),_orange=Color(0xFFF46627),_cream=Color(0xFFF4EEE1);

class AdminAdvertisementsPage extends StatefulWidget {
 const AdminAdvertisementsPage({super.key});
 @override State<AdminAdvertisementsPage> createState()=>_AdminAdvertisementsPageState();
}
class _AdminAdvertisementsPageState extends State<AdminAdvertisementsPage> {
 bool loading=true; String? error;
 List<Map<String,dynamic>> ads=[];
 @override void initState(){super.initState();reload();}
 Future<void> reload() async {
  setState((){loading=true;error=null;});
  try {final result=await AdvertisementAdminService.instance.all();if(mounted)setState(()=>ads=result);}
  catch(e){if(mounted)setState(()=>error=e.toString());}
  finally{if(mounted)setState(()=>loading=false);}
 }
 Future<void> edit([Map<String,dynamic>? ad]) async {
  final result=await Navigator.push<bool>(context,MaterialPageRoute(builder:(_)=>_AdvertisementEditor(ad:ad)));
  if(result==true)reload();
 }
 Future<void> remove(Map<String,dynamic> ad) async {
  final yes=await showDialog<bool>(context:context,builder:(c)=>AlertDialog(
   title:const Text('Delete advertisement?'),content:Text('${ad['title']??'This advertisement'} will be permanently deleted.'),
   actions:[TextButton(onPressed:()=>Navigator.pop(c,false),child:const Text('Cancel')),
    TextButton(onPressed:()=>Navigator.pop(c,true),child:const Text('Delete'))]));
  if(yes!=true)return;
  try {await AdvertisementAdminService.instance.delete((ad['id'] as num).toInt());await reload();}
  catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('$e')));}
 }
 @override Widget build(BuildContext context)=>Scaffold(
  backgroundColor:_cream,
  appBar:AppBar(title:const Text('Advertisement Management'),backgroundColor:_green,foregroundColor:Colors.white,
   actions:[IconButton(onPressed:reload,icon:const Icon(Icons.refresh))]),
  floatingActionButton:FloatingActionButton.extended(backgroundColor:_orange,foregroundColor:Colors.white,
   onPressed:()=>edit(),icon:const Icon(Icons.add),label:const Text('New advert')),
  body:loading?const Center(child:CircularProgressIndicator()):
   error!=null?Center(child:Padding(padding:const EdgeInsets.all(24),child:Text(error!,textAlign:TextAlign.center))):
   ads.isEmpty?const Center(child:Text('No advertisements yet. Tap New advert to upload your first poster.')):
   ListView.builder(padding:const EdgeInsets.fromLTRB(16,16,16,96),itemCount:ads.length,itemBuilder:(context,index){
    final ad=ads[index];final path=ad['image_path']?.toString();
    final url=path==null?null:AuthService.storageUrl(path);
    return Card(color:Colors.white,margin:const EdgeInsets.only(bottom:12),clipBehavior:Clip.antiAlias,
     child:Padding(padding:const EdgeInsets.all(12),child:Row(children:[
      SizedBox(width:85,height:115,child:url==null?const Icon(Icons.image):Image.network(url,fit:BoxFit.contain,errorBuilder:(_,__,___)=>const Icon(Icons.broken_image))),
      const SizedBox(width:12),
      Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
       Text('${ad['title']??''}',style:const TextStyle(fontWeight:FontWeight.bold,fontSize:16)),
       const SizedBox(height:4),Text('${ad['advertiser_name']??''}'),
       const SizedBox(height:4),Text('${ad['placement']??''}',style:const TextStyle(fontSize:12,color:_green)),
       Text(ad['is_active']==true?'Published':'Paused',style:TextStyle(color:ad['is_active']==true?_green:_orange,fontWeight:FontWeight.w600)),
       Text('Views ${ad['impressions']??0} · Clicks ${ad['clicks']??0}',style:const TextStyle(fontSize:12)),
       Row(children:[TextButton(onPressed:()=>edit(ad),child:const Text('Edit')),TextButton(onPressed:()=>remove(ad),child:const Text('Delete'))]),
      ])),
     ])));
   }),
 );
}
class _AdvertisementEditor extends StatefulWidget {
 final Map<String,dynamic>? ad;
 const _AdvertisementEditor({this.ad});
 @override State<_AdvertisementEditor> createState()=>_AdvertisementEditorState();
}
class _AdvertisementEditorState extends State<_AdvertisementEditor> {
 final form=GlobalKey<FormState>();
 late final title=TextEditingController(text:'${widget.ad?['title']??''}');
 late final advertiser=TextEditingController(text:'${widget.ad?['advertiser_name']??''}');
 late final description=TextEditingController(text:'${widget.ad?['description']??''}');
 late final actionValue=TextEditingController(text:'${widget.ad?['action_value']??''}');
 late final start=TextEditingController(text:'${widget.ad?['starts_at']??''}'.split('.').first.replaceAll('T',' '));
 late final end=TextEditingController(text:'${widget.ad?['ends_at']??''}'.split('.').first.replaceAll('T',' '));
 late final order=TextEditingController(text:'${widget.ad?['sort_order']??0}');
 late String placement='${widget.ad?['placement']??'homepage_carousel'}';
 late String action='${widget.ad?['action_type']??'none'}';
 late bool active=widget.ad?['is_active']==true;
 late Set<String> countries=Set<String>.from(widget.ad?['countries'] is List?widget.ad!['countries']:[]);
 XFile? image;bool saving=false;
 @override void dispose(){for(final c in [title,advertiser,description,actionValue,start,end,order]){c.dispose();}super.dispose();}
 Future<void> pick()async {
  final file=await ImagePicker().pickImage(source:ImageSource.gallery,imageQuality:95);
  if(file!=null)setState(()=>image=file);
 }
 Future<void> date(TextEditingController controller) async {
  final value=await showDatePicker(context:context,initialDate:DateTime.now(),firstDate:DateTime(2020),lastDate:DateTime(2040));
  if(value!=null)controller.text='${value.year}-${value.month.toString().padLeft(2,'0')}-${value.day.toString().padLeft(2,'0')} 00:00:00';
 }
 Future<void> save()async {
  if(!form.currentState!.validate())return;
  if(widget.ad==null&&image==null){ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Choose a poster image.')));return;}
  setState(()=>saving=true);
  try {
   final fields=<String,String>{
    'title':title.text.trim(),'advertiser_name':advertiser.text.trim(),
    'description':description.text.trim(),'placement':placement,'action_type':action,
    'action_value':actionValue.text.trim(),'is_active':active?'1':'0',
    'sort_order':order.text.trim().isEmpty?'0':order.text.trim(),
    'starts_at':start.text.trim(),'ends_at':end.text.trim(),
   };
   for(var i=0;i<countries.length;i++){fields['countries[$i]']=countries.elementAt(i);}
   // An empty countries list targets every country.
   if(countries.isEmpty)fields['countries']='';
   await AdvertisementAdminService.instance.save(id:widget.ad?['id'] is num?(widget.ad!['id'] as num).toInt():null,fields:fields,image:image);
   if(mounted)Navigator.pop(context,true);
  }catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('Save failed: $e')));}
  finally{if(mounted)setState(()=>saving=false);}
 }
 @override Widget build(BuildContext context)=>Scaffold(
  backgroundColor:_cream,appBar:AppBar(title:Text(widget.ad==null?'New Advertisement':'Edit Advertisement'),backgroundColor:_green,foregroundColor:Colors.white),
  body:Form(key:form,child:ListView(padding:const EdgeInsets.all(18),children:[
   Card(color:Colors.white,child:Padding(padding:const EdgeInsets.all(16),child:Column(children:[
    if(widget.ad?['image_path']!=null)Image.network(AuthService.storageUrl(widget.ad!['image_path'].toString()),height:180,fit:BoxFit.contain),
    if(image!=null)Padding(padding:const EdgeInsets.all(8),child:Text('Selected: ${image!.name}')),
    OutlinedButton.icon(onPressed:pick,icon:const Icon(Icons.add_photo_alternate_outlined),label:Text(image==null?'Choose poster':'Change poster')),
    const Text('JPG, PNG or WebP · Up to 10 MB',style:TextStyle(fontSize:12)),
   ]))),
   const SizedBox(height:12),
   TextFormField(controller:title,decoration:const InputDecoration(labelText:'Advertisement title'),validator:(v)=>v==null||v.trim().isEmpty?'Required':null),
   TextFormField(controller:advertiser,decoration:const InputDecoration(labelText:'Advertiser name'),validator:(v)=>v==null||v.trim().isEmpty?'Required':null),
   TextFormField(controller:description,maxLines:3,decoration:const InputDecoration(labelText:'Description (optional)')),
   const SizedBox(height:12),
   DropdownButtonFormField<String>(value:placement,decoration:const InputDecoration(labelText:'Homepage placement'),
    items:const [DropdownMenuItem(value:'homepage_carousel',child:Text('Sponsored carousel')),DropdownMenuItem(value:'homepage_inline',child:Text('Inline sponsored card'))],
    onChanged:(v)=>setState(()=>placement=v??placement)),
   DropdownButtonFormField<String>(value:action,decoration:const InputDecoration(labelText:'Tap action'),
    items:const [DropdownMenuItem(value:'none',child:Text('None')),DropdownMenuItem(value:'website',child:Text('Website')),DropdownMenuItem(value:'whatsapp',child:Text('WhatsApp')),DropdownMenuItem(value:'phone',child:Text('Phone'))],
    onChanged:(v)=>setState(()=>action=v??action)),
   TextFormField(controller:actionValue,decoration:const InputDecoration(labelText:'Website URL / WhatsApp number / phone')),
   const SizedBox(height:16),const Text('Show in countries (none selected = all)',style:TextStyle(fontWeight:FontWeight.w600)),
   for(final country in const ['Uganda','Rwanda','Kenya','Tanzania'])
    CheckboxListTile(dense:true,title:Text(country),value:countries.contains(country),
     onChanged:(v)=>setState((){if(v==true){countries.add(country);}else{countries.remove(country);}})),
   const SizedBox(height:12),
   TextField(readOnly:true,controller:start,onTap:()=>date(start),decoration:const InputDecoration(labelText:'Start date (optional)',suffixIcon:Icon(Icons.calendar_month))),
   TextField(readOnly:true,controller:end,onTap:()=>date(end),decoration:const InputDecoration(labelText:'End date (optional)',suffixIcon:Icon(Icons.calendar_month))),
   TextFormField(controller:order,keyboardType:TextInputType.number,decoration:const InputDecoration(labelText:'Display order')),
   SwitchListTile(title:const Text('Published'),subtitle:const Text('Only published adverts appear in the app'),value:active,activeColor:_green,onChanged:(v)=>setState(()=>active=v)),
   const SizedBox(height:18),
   FilledButton.icon(style:FilledButton.styleFrom(backgroundColor:_green,padding:const EdgeInsets.all(16)),
    onPressed:saving?null:save,icon:const Icon(Icons.save_outlined),label:Text(saving?'Saving...':'Save Advertisement')),
   const SizedBox(height:36),
  ])),
 );
}
