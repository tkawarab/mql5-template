#include <Files\FileTxt.mqh>
#include <Arrays\ArrayString.mqh>
class CDataFile
 {
   private:
      CArrayString*     array_value;
      CFileTxt    OFileTxt;
   public:
      CDataFile(string file_name,bool rewrite);
      ~CDataFile(){ OFileTxt.Close();
                     if(array_value!=NULL) delete array_value;
                   };
      virtual     CArrayString*     find(CArrayString* find_array,datetime start,datetime end,int count,string keyword);
      virtual     bool     writeline(string record);
      virtual     void     append_array_value(string value);
      virtual     void     write_array_value(string delims);
      virtual     void     reset_array_value();
      virtual     void     file_to_array(string &array);
      CArrayString*     read();
 };
 
CDataFile::CDataFile(string file_name,bool rewrite){
  
  OFileTxt.SetCommon(true);
  
  if(rewrite){
     if(OFileTxt.IsExist(file_name,FILE_COMMON)){ OFileTxt.Delete(file_name,FILE_COMMON); }
  } 
  
  if(!OFileTxt.IsExist(file_name,FILE_COMMON)){
      //OFileTxt.Open(file_name,FILE_WRITE|FILE_READ|FILE_UNICODE|FILE_TXT|FILE_SHARE_READ|FILE_SHARE_WRITE,',');
      OFileTxt.Open(file_name,FILE_WRITE|FILE_READ|FILE_ANSI|FILE_TXT|FILE_SHARE_READ|FILE_SHARE_WRITE,',');
  } else {  
      //OFileTxt.Open(file_name,FILE_WRITE|FILE_READ|FILE_UNICODE|FILE_TXT|FILE_SHARE_READ|FILE_SHARE_WRITE,',');
      OFileTxt.Open(file_name,FILE_WRITE|FILE_READ|FILE_ANSI|FILE_TXT|FILE_SHARE_READ|FILE_SHARE_WRITE,',');
  }

}

void CDataFile::reset_array_value(){
   if(array_value==NULL)
      array_value = new CArrayString();
   array_value.Clear();
}
 
void CDataFile::append_array_value(string value){
   array_value.Add(value);
}

void CDataFile::write_array_value(string delims){
   string line;
   for(int i=0;i<array_value.Total();i++){
      if(array_value.At(i)=="\r\n"){
         line = line + array_value.At(i);
      } else {
         line = line + array_value.At(i)+ delims;
      }
   }
   writeline(line);
}
 
bool CDataFile::writeline(string record){

   OFileTxt.Seek(0,SEEK_END);
   
   OFileTxt.WriteString(record);
   OFileTxt.WriteString("\r\n");

   return true;
}


CArrayString* CDataFile::read(){

   CArrayString* result_array = new CArrayString;
   string read_line;
   while(!OFileTxt.IsEnding()){
      read_line = OFileTxt.ReadString();
      result_array.Add(read_line);   
   }
   return result_array;
}


CArrayString* CDataFile::find(CArrayString* find_array,datetime start,datetime end,int count,string keyword){
   CArrayString* temp_array = new CArrayString;
   CArrayString* result_array = new CArrayString;
   string read_line;
   string rec[];
   ushort u_sep=StringGetCharacter(",",0); 
   datetime check_time;
     
   if(find_array==NULL){
   
      find_array = this.read();

   }
   
   if(start==NULL){ start = StringToTime("1970.01.01 01:01"); }
   if(end==NULL){ end = TimeCurrent(); }

   for(int i=0; i<find_array.Total();i++){
      read_line = find_array.At(i);
      StringSplit(read_line,u_sep,rec);
      
      check_time = StringToTime(rec[0]);
      if(start <= check_time && end >= check_time){
         if(keyword==NULL){
            temp_array.Add(read_line);
            continue;
         }
         for(int i2=0; i2<ArraySize(rec); i2++){
            if(rec[i2]==keyword){
               temp_array.Add(read_line);
               continue;
            }
         }
      }
   }
   
   if(count==NULL){ count = temp_array.Total(); }
   temp_array.Sort(0); //ASC
   for(int i=temp_array.Total()-1; i>=0;i--){
//   for(int i=0; i<temp_array.Total(); i++){
     if(count>=temp_array.Total()-i){
//     if(count>i){
        result_array.Add(temp_array.At(i));
     }
   }
   delete find_array;
   delete temp_array;

   return result_array;
}