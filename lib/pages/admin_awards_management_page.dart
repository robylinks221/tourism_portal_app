import 'package:flutter/material.dart';
import '../services/admin_awards_service.dart';

class AdminAwardsManagementPage extends StatefulWidget {
 const AdminAwardsManagementPage({super.key,this.awardCycleId=1});
 final int awardCycleId;
 @override State<AdminAwardsManagementPage> createState()=>_State();
}
class _State extends State<AdminAwardsManagementPage>{
 static const green=Color(0xFF165B5D),orange=Color(0xFFF46627),bg=Color(0xFFF4EEE1);
 static const stages=['nominations_open','verification','judging','finalists_announced','public_voting_open','voting_closed','winners_announced'];
 static const visibilities=['hidden','percentage','full'];
 final title=TextEditingController(),intro=TextEditingController();
 bool loading=true,saving=false,active=false,published=false; String? error;
 String stage='nominations_open',visibility='hidden'; DateTime? opens,closes; Map<String,dynamic>? award;

 @override void initState(){super.initState();load();}
 @override void dispose(){title.dispose();intro.dispose();super.dispose();}
 bool b(dynamic v)=>v==true||v==1||v?.toString()=='1';
 DateTime? d(dynamic v)=>v==null?null:DateTime.tryParse(v.toString())?.toLocal();
 String label(String s)=>{'nominations_open':'Nominations Open','verification':'Verification','judging':'Judging','finalists_announced':'Finalists Announced','public_voting_open':'Public Voting Open','voting_closed':'Voting Closed','winners_announced':'Winners Announced'}[s]??s;
 String err(Object e)=>e.toString().replaceFirst('ApiException: ','');
 void apply(Map<String,dynamic> a){title.text=a['title']?.toString()??'';intro.text=a['introduction']?.toString()??'';stage=stages.contains(a['stage'])?a['stage'].toString():stages.first;visibility=visibilities.contains(a['results_visibility'])?a['results_visibility'].toString():'hidden';active=b(a['is_active']);published=b(a['is_published']);opens=d(a['voting_opens_at']);closes=d(a['voting_closes_at']);}
 Future<void> load() async {setState((){loading=true;error=null;});try{final a=await AdminAwardsService.instance.awardCycle(widget.awardCycleId);if(!mounted)return;apply(a);setState((){award=a;loading=false;});}catch(e){if(!mounted)return;setState((){loading=false;error=err(e);});}}
 void snack(String s){ScaffoldMessenger.of(context)..hideCurrentSnackBar()..showSnackBar(SnackBar(content:Text(s)));}
 String dateText(DateTime? x)=>x==null?'Not set':'${x.day.toString().padLeft(2,'0')}/${x.month.toString().padLeft(2,'0')}/${x.year}  ${x.hour.toString().padLeft(2,'0')}:${x.minute.toString().padLeft(2,'0')}';
 Future<DateTime?> pick(DateTime? current) async {final now=DateTime.now(),initial=current??now.add(const Duration(days:1));final date=await showDatePicker(context:context,initialDate:initial,firstDate:DateTime(now.year-1),lastDate:DateTime(now.year+5));if(date==null||!mounted)return null;final time=await showTimePicker(context:context,initialTime:TimeOfDay.fromDateTime(initial));if(time==null)return null;return DateTime(date.year,date.month,date.day,time.hour,time.minute);}
 bool validVoting(){if(opens==null||closes==null){snack('Set both voting opening and closing dates first.');return false;}if(!closes!.isAfter(opens!)){snack('Voting closing time must be after opening time.');return false;}return true;}

 Future<void> changeStage(String next) async {
  if(next==stage)return;if(next=='public_voting_open'&&!validVoting())return;
  final ok=await showDialog<bool>(context:context,builder:(c)=>AlertDialog(title:const Text('Change awards stage?'),content:Text('Move this awards cycle from ${label(stage)} to ${label(next)}?'),actions:[TextButton(onPressed:()=>Navigator.pop(c,false),child:const Text('Cancel')),FilledButton(onPressed:()=>Navigator.pop(c,true),child:const Text('Confirm'))]))??false;
  if(!ok)return;final old=stage;setState(()=>stage=next);try{await save(success:false);if(mounted)snack('Stage changed to ${label(next)}.');}catch(_){if(mounted)setState(()=>stage=old);}
 }
 Future<void> save({bool success=true}) async {
  if(saving)return;if(title.text.trim().isEmpty){snack('Award title is required.');throw StateError('title');}
  if(opens!=null&&closes!=null&&!closes!.isAfter(opens!)){snack('Voting closing time must be after opening time.');throw StateError('dates');}
  if(stage=='public_voting_open'&&!validVoting())throw StateError('dates');
  setState(()=>saving=true);
  try{final a=await AdminAwardsService.instance.updateAwardCycle(widget.awardCycleId,title:title.text.trim(),introduction:intro.text.trim(),stage:stage,votingOpensAt:opens?.toUtc().toIso8601String(),votingClosesAt:closes?.toUtc().toIso8601String(),resultsVisibility:visibility,isActive:active,isPublished:published);if(!mounted)return;apply(a);setState((){award=a;saving=false;});if(success)snack('Award settings saved.');}catch(e){if(mounted){setState(()=>saving=false);snack(err(e));}rethrow;}
 }
 @override Widget build(BuildContext context)=>Scaffold(backgroundColor:bg,appBar:AppBar(backgroundColor:green,foregroundColor:Colors.white,title:const Text('Award Management')),body:loading?const Center(child:CircularProgressIndicator()):error!=null?Center(child:Padding(padding:const EdgeInsets.all(24),child:Column(mainAxisSize:MainAxisSize.min,children:[Text(error!,textAlign:TextAlign.center),const SizedBox(height:12),FilledButton(onPressed:load,child:const Text('Try Again'))]))):ListView(padding:const EdgeInsets.all(18),children:[
  Container(padding:const EdgeInsets.all(20),decoration:BoxDecoration(color:green,borderRadius:BorderRadius.circular(22)),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text('${award?['year']??''} Tourist Guide Awards',style:const TextStyle(color:Colors.white70,fontWeight:FontWeight.w700)),const SizedBox(height:7),Text(title.text,style:const TextStyle(color:Colors.white,fontSize:22,fontWeight:FontWeight.w800)),const SizedBox(height:12),Chip(label:Text(label(stage)))])),
  const SizedBox(height:14),card('Awards Stage',DropdownButtonFormField<String>(value:stage,decoration:const InputDecoration(labelText:'Current stage',border:OutlineInputBorder()),items:stages.map((x)=>DropdownMenuItem(value:x,child:Text(label(x)))).toList(),onChanged:saving?null:(x){if(x!=null)changeStage(x);})),
  const SizedBox(height:14),card('Award Details',Column(children:[TextField(controller:title,decoration:const InputDecoration(labelText:'Award title',border:OutlineInputBorder())),const SizedBox(height:12),TextField(controller:intro,minLines:4,maxLines:8,decoration:const InputDecoration(labelText:'Introduction',border:OutlineInputBorder(),alignLabelWithHint:true))])),
  const SizedBox(height:14),card('Public Voting',Column(children:[dateRow('Voting opens',opens,()async{final x=await pick(opens);if(x!=null&&mounted)setState(()=>opens=x);}),const Divider(),dateRow('Voting closes',closes,()async{final x=await pick(closes);if(x!=null&&mounted)setState(()=>closes=x);}),const SizedBox(height:12),DropdownButtonFormField<String>(value:visibility,decoration:const InputDecoration(labelText:'Results visibility',border:OutlineInputBorder()),items:visibilities.map((x)=>DropdownMenuItem(value:x,child:Text(x[0].toUpperCase()+x.substring(1)))).toList(),onChanged:saving?null:(x){if(x!=null)setState(()=>visibility=x);})])),
  const SizedBox(height:14),card('Publication',Column(children:[SwitchListTile.adaptive(contentPadding:EdgeInsets.zero,title:const Text('Active awards cycle'),value:active,onChanged:saving?null:(x)=>setState(()=>active=x)),SwitchListTile.adaptive(contentPadding:EdgeInsets.zero,title:const Text('Published'),value:published,onChanged:saving?null:(x)=>setState(()=>published=x))])),
  const SizedBox(height:18),SizedBox(height:52,child:FilledButton.icon(style:FilledButton.styleFrom(backgroundColor:orange),onPressed:saving?null:()async{try{await save();}catch(_){}},icon:const Icon(Icons.save_outlined),label:Text(saving?'Saving...':'Save Award Settings'))),const SizedBox(height:20)
 ]));
 Widget card(String heading,Widget child)=>Container(padding:const EdgeInsets.all(18),decoration:BoxDecoration(color:Colors.white,borderRadius:BorderRadius.circular(20)),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(heading,style:const TextStyle(color:green,fontSize:17,fontWeight:FontWeight.w800)),const SizedBox(height:14),child]));
 Widget dateRow(String name,DateTime? value,VoidCallback tap)=>InkWell(onTap:saving?null:tap,child:Padding(padding:const EdgeInsets.symmetric(vertical:8),child:Row(children:[const Icon(Icons.calendar_month_outlined,color:green),const SizedBox(width:12),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(name,style:const TextStyle(fontWeight:FontWeight.w700)),Text(dateText(value))])),const Icon(Icons.chevron_right_rounded)])));
}
