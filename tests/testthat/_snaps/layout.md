# layouts compare by value and print as a field diagram

    Code
      print(id_layout("twitter"))
    Output
      <zuid_layout twitter>
      | sign 1 | time 41 | datacenter 5 | worker 5 | sequence 12 |
      time: ms units from 2010-11-04T01:42:54.657Z

---

    Code
      print(id_layout("sonyflake", epoch = 0))
    Output
      <zuid_layout sonyflake>
      | sign 1 | time 39 | sequence 8 | machine 16 |
      time: 10ms units from 1970-01-01T00:00:00.000Z

